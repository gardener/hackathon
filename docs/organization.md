# Organizing the topics for a hackathon

This section should serve as a kind of playbook for organizing a Gardener Hackathon.
It is only relevant if you are organizing one.

> [!NOTE]
> This guide is neither a _rule_-book nor is it probably exhaustive. Take it as tips and recommendations based on our past experiences.

## Overview

The process can be basically stripped down to a couple of phases.
You can jump to the one that is currently applicable for you:

1. [Topic Collection Phase](#topic-collection-phase)
    - Create and change label in the topic issue template
    - Set up topic collection meeting
1. [Voting Phase](#voting-phase)
1. [Assignment Phase](#assignment-phase)
1. [Hackathon Start](#hackathon-start)
1. [Mid-week presentations](#mid-week-presentations)
1. [Final presentations](#final-presentations)
1. [Prepare review meeting](#prepare-review-meeting)

## Topic Collection Phase

Topic collection can happen all the time for the next hackathon, as not all of them are worked on in all hackathons.

Around 4 weeks in advance, you should create a new label that indicates when the next hackathon will happen (e.g. `Q2/2026`).
After that, you should also update the default label in the [issue template](.github/ISSUE_TEMPLATE/hackathon-topic.md).
For topics left over from previous hackathons, you can contact the authors to ask if they want to include them in this hackathon's voting as well.

Around 2 weeks before the start of the hackathon, you should announce the topic collection meeting.
This is a meeting, which can be scheduled for roughly 1 hour, where all of the collected topics are presented by the creators of the topic.

## Voting Phase

Shortly before the topic collection meeting starts, you should start the voting phase, so the topics are ready to be voted on after the meeting.
For this, you have to start the [`start-voting`](.github/workflows/start-voting.yml) workflow.
It requires a GitHub PAT called `DISCUSSION_TOKEN` to be present in the repo.
So please ensure there is an Action Secret variable that contains a PAT that is allowed to create and edit discussions in this repository.

For this action to run, you need to specify the label of this hackathon (e.g. `Q2/2026`) that you created earlier.

There is a small [script](tools/presentation-order.sh) that takes the discussion number created for this voting phase and the repository (e.g. `./tools/presentation-order.sh 41 gardener/hackathon`), which generates a `presentation-order.md` that you can use as an agenda for the meeting.
Make sure that if a topic owner is not present in the meeting / hackathon, they arrange someone to present it instead.

## Assignment Phase

Around 3 work days before the hackathon starts, you should close the voting, by executing the [`close-voting`](.github/workflows/close-voting.yml) workflow, with the current hackathon label and a comma-separated list of the attendees GitHub usernames.
This will generate a table in the discussion that sorts the topics by votes and assigns everybody to any topic they voted interest in.

To do the first, soft-assignment of people to topics, you can use the vibe-coded [`assign-teams.html`](tools/assign-teams.html) tool to assign the attendees based on the topics they showed interest in.
The tool takes:
- The generated table after the closing of the voting
- A list (newline separated) of the attendees (GitHub handles) and optionally their company assignment (personA:companyA)

With that you can drag and drop people to soft-assign them to a topic. It will warn you if you assign only people from the same company, as we try to mix people from different companies to work together in order to foster more exchange.

When you are done assigning everyone, you can copy the resulting table below and replace the initial table in the discussion.

## Hackathon Start

When everyone has arrived at the location, to kick off the event, we usually start with an introduction round moderated by you.

After this is done, we start hacking in the individual teams. This is where the fun begins!

## Mid-week presentations

On Wednesday morning, we do a quick update on what each team achieved. This is also initiated and moderated by you.

It is best to keep the length to around 1 hour and strictly time box the length of each team accordingly, so that everyone gets an idea what the other teams have achieved.

## Final presentations

On the last day, the same process as the [Mid-week presentations](#mid-week-presentations) occurs, where each team concludes what they did and how the topic will continue.

During that time, you should already ask which people will continue on the topic and who will present the achievements in the review meeting.

## Prepare review meeting

1 or 2 weeks after the hackathon, we do a special edition of the Gardener review meeting, where the results of the hackathon are presented to the community.

For this, you should prepare the agenda, as to which topic gets presented by whom and also moderate this meeting. The meeting is usually scheduled for 1.5 hours.