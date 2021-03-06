### Migration Procedure Notes

A random collection of commands for launch day. 

**DevOps Requirments**:  Nothing stored on local file except for application code.

#### Pre Procedure:
```
Have django, accounts, and osc env up and running
```


#### Procedure:
```
osc$ export RAILS_ENV=production

#Export all users from osc  (File will export as a .csv)
osc$ rake db:dump_users 

# Alternative command 
osc$ rbenv exec bundle exec rake db:dump_users

# export a seperate faculty list of users using rails console.
osc$ rbenv exec bundle exec rails c
rails>

faculty_users = User.joins{faculty_profile}.where{faculty_profile.is_verified == true}.all
require 'csv'
CSV.open("faculty.csv","w") do |csv|
  csv << ["last_name","first_name","college_website_url","email","institutional_email_address","department","address","phone_number"]
  faculty_users.each do |row|
    csv << [row.last_name,row.first_name,row.college_website_url,row.email,row.institutional_email_address,row.department,row.address,row.phone_number]
  end
end

# Enter accounts create env variable
accounts$ export RAILS_ENV=production

# copy files to accounts production

# Log in as ostaccounts user
accounts$ sudo su ostaccounts

# Create admin (optional)
accounts$ rbenv exec bundle exec rake accounts:create_admin[admin,password]

#check oauth app list
accounts$ rbenv exec bundle exec rake accounts:oauth_apps:list 

# If Admin_Tool app does not exist create it
accounts$ rbenv exec bundle exec rake accounts:oauth_apps:create APP_NAME=Admin_Tool USERNAME=admin REDIRECT_URI=http://localhost/callback 

# Import users into accounts db
accounts$ rbenv exec bundle exec rake accounts:import_users CSV_FILE=<filename> --trace APP_NAME=Admin_Tool

# Export contact list from accounts db (this file is needed to match faculty users from osc with their new accounts id in salesforce)
# found in config/database.yml
accounts$ pg_dump -t contact_infos -U ostaccounts -h openstax-dev-db.casdfasdfnll.us-west-1.rds.amazonaws.com accounts_dev > contact_infos.sql"

# Also export user list from accounts db (this file is needed to match faculty users from osc with their new accounts id in cms)
# found in config/database.yml
accounts$ pg_dump -t users -U ostaccounts -h openstax-dev-db.casdfasdfnll.us-west-1.rds.amazonaws.com accounts_dev > users.sql"

# Use "faculty.csv" and "contact_infos.sql" to match every faculty user to an accounts ID (JOIN on email)
# Give this file to salesforce

# Use "faculty.csv" and "users.sql", (might need contact_infos.sql to filter out faculty users), to generate a csv list of users and import the list into cms system. 
# see https://github.com/openstax/openstax-cms/blob/master/accounts/test_users.csv for an example import file

# Import users into cms
oscms$ python manage.py import_users users.csv

```


