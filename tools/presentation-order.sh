#!/usr/bin/env bash
# Generates a presentation order markdown file for a hackathon topic voting discussion.
# Topics are grouped by author, sorted by issue number ascending within each group.
# Groups are sorted by descending topic count, ties broken by lowest issue number.
#
# Usage: ./scripts/presentation-order.sh <discussion-number> [owner/repo]
# Example: ./scripts/presentation-order.sh 41
#          ./scripts/presentation-order.sh 41 gardener/hackathon

set -euo pipefail

DISCUSSION="${1:?Usage: $0 <discussion-number> [owner/repo]}"
REPO="${2:-gardener/hackathon}"
OUTPUT="presentation-order.md"

echo "Fetching discussion #${DISCUSSION} from ${REPO}..."

# Collect all comments (paginate if needed — 100 per page)
ISSUE_NUMBERS=()
cursor=""
while true; do
  if [[ -z "$cursor" ]]; then
    after_arg=""
  else
    after_arg=", after: \"${cursor}\""
  fi

  result=$(gh api graphql -f query="
    {
      repository(owner: \"${REPO%/*}\", name: \"${REPO#*/}\") {
        discussion(number: ${DISCUSSION}) {
          comments(first: 100${after_arg}) {
            pageInfo { hasNextPage endCursor }
            nodes { body }
          }
        }
      }
    }
  ")

  # Extract issue numbers from <!-- hackathon-topic-vote:N --> markers
  while IFS= read -r num; do
    ISSUE_NUMBERS+=("$num")
  done < <(echo "$result" | grep -oP '(?<=hackathon-topic-vote:)\d+')

  has_next=$(echo "$result" | gh api graphql --jq '.data.repository.discussion.comments.pageInfo.hasNextPage' 2>/dev/null || echo "false")
  # Use python to parse JSON reliably
  has_next=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['data']['repository']['discussion']['comments']['pageInfo']['hasNextPage'])")
  cursor=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['data']['repository']['discussion']['comments']['pageInfo']['endCursor'] or '')")

  if [[ "$has_next" != "True" ]]; then
    break
  fi
done

if [[ ${#ISSUE_NUMBERS[@]} -eq 0 ]]; then
  echo "No hackathon-topic-vote markers found in discussion #${DISCUSSION}." >&2
  exit 1
fi

echo "Found ${#ISSUE_NUMBERS[@]} topics. Fetching issue authors..."

# Fetch each issue: number, title, author
declare -A ISSUE_TITLE
declare -A ISSUE_AUTHOR

for num in "${ISSUE_NUMBERS[@]}"; do
  data=$(gh api "repos/${REPO}/issues/${num}" --jq '[.number, .title, .user.login] | @tsv')
  IFS=$'\t' read -r n title author <<< "$data"
  ISSUE_TITLE[$n]="$title"
  ISSUE_AUTHOR[$n]="$author"
done

# Group issues by author; track each author's minimum issue number for group ordering
declare -A AUTHOR_MIN_ISSUE
declare -A AUTHOR_ISSUES  # space-separated list of issue numbers per author

for num in "${ISSUE_NUMBERS[@]}"; do
  author="${ISSUE_AUTHOR[$num]}"
  if [[ -z "${AUTHOR_MIN_ISSUE[$author]+x}" ]] || (( num < AUTHOR_MIN_ISSUE[$author] )); then
    AUTHOR_MIN_ISSUE[$author]=$num
  fi
  AUTHOR_ISSUES[$author]="${AUTHOR_ISSUES[$author]:-} $num"
done

# Sort authors by descending topic count, ties broken by lowest issue number
sorted_authors=$(
  for author in "${!AUTHOR_MIN_ISSUE[@]}"; do
    count=$(echo "${AUTHOR_ISSUES[$author]}" | tr ' ' '\n' | grep -vc '^$')
    echo "$count ${AUTHOR_MIN_ISSUE[$author]} $author"
  done | sort -k1,1rn -k2,2n | awk '{print $3}'
)

# Build markdown
{
  echo "# Hackathon Topic Presentation Order"
  echo ""
  echo "Topics are grouped by author, ordered by issue number (ascending) within each group."
  echo "Groups are ordered by topic count (descending), ties broken by lowest issue number."
  echo ""

  echo "| Topic | Presenter |"
  echo "|-------|-----------|"

  first=1
  while IFS= read -r author; do
    sorted_issues=$(echo "${AUTHOR_ISSUES[$author]}" | tr ' ' '\n' | grep -v '^$' | sort -n)
    if [[ "$first" -eq 0 ]]; then
      echo "|---|---|"
    fi
    first=0
    while IFS= read -r num; do
      title="${ISSUE_TITLE[$num]}"
      echo "| [#${num} - ${title}](https://github.com/${REPO}/issues/${num}) | @${author} |"
    done <<< "$sorted_issues"
  done <<< "$sorted_authors"
} > "$OUTPUT"

echo "Written to ${OUTPUT}"
