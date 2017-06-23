# Trigger the synchronisation of all users having an email address
user_ids = User.where.not(email: nil).pluck(:id)
SalesforceSync::Api.bulk_synchronisation(User => user_ids)
