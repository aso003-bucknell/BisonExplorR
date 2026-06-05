usethis::use_git()

#create token on github
usethis::create_github_token()

#save token
gitcreds::gitcreds_set()

usethis::use_github()



#create tutorial folder structure
usethis::use_tutorial("01-intro-to-r", "Introduction to R and Data Import")
usethis::use_tutorial("02-data-wrangling", "Data Wrangling and Visualization")
usethis::use_tutorial("03-statistics", "Statistical Analysis")


usethis::use_logo("G:/Other computers/My Laptop/Documents/IDEA_Grant_2026_BisonDiscovR/bucky_explorR_logo.png")


#create a readme
usethis::use_readme_md()
