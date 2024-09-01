# Smeg Timetrials

## Showcase
https://vimeo.com/1005233314?share=copy

## Description
Smeg Timetrials is an easy way to enhance the racing scene in your server! Simply create a track (or use some of the pre-created ones) and find out who the fastest racer is!

View the config file for potential customizations.

### Main Features
- Custom HUD showing player name, current time and delta
  - Delta is compared to the **fastest** time set
- Top 5 leaderboard display
- Ability to reset the race (Can be toggled on/off)
- Vehicle phasing for the first 5 seconds of the race to prevent being struck by traffic/other players when waiting for the count down.
- Race cooldown (Time can be configured)
## Performance Stats
- 0.00ms idle, when away from a marker
- 0.10ms when close to a marker, but not close enough to draw the scores
- 0.25ms when drawing scores (Uses a lot of text natives)
- 0.07-0.10ms when in race