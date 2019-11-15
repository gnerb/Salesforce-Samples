# Salesforce Samples

# Overview
I wrote this primary as a learning tool and tried to get it to do as much as possible. This component was embeded into a community and into lightning record pages.

I'm uploading this for later reference and in hopes of it helping others learn about LWC.


# Contractor Search
Embeded into a lightning record page. It will automatically pull data from the record to pre-populate search criteria. This should allow users to search for contractors for a given requisition without needing to manually enter search criteria.

The form updates itself when the associated record is updated as well making it quite dynamic.

The apex controller will build a list of defined cities/sates based on the cities/states of all contacts in the system. While this will not be a good approach in large systems, it was a good enough learning tool.

It will search for contacts with a given record type matching the criteria and return a list of contacts for the user to pick from.

Finally, a button is provided for assigning the contact which creates a junction object to associate the records.

