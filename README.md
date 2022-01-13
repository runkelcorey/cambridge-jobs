# cambridge-jobs
Shiny application to find Cambridge, MA jobs

# motivation
Cambridge, MA jobs listings are impossible to search or filter and are ugly

# goal
Create a Shiny application that can:
+ search job descriptions
+ filter by posting date, weekly hours, rate, physical demands(?), job code,
union affiliation
+ provide hyperlinks to job listings (looking at you, Workday)
+ automatically update each day

## to-do (server)
- [x] identify CSS path of job listings
- [x] identify CSS path of each listings' attributes
- [x] define data architecture (SQLite? CSV?)
- [ ] research best practices for Shiny database front-ends

## to-do (ui)
- [ ] left panel: filters
- [x] main panel: job listings
- [ ] top panel: search bar, download button
