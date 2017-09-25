# Calendar Invite Class

This class provides a way to create calendar invites for scheduling meetings with 
users/contacts. The class serializes to a string that can be dropped on a VF page
and downloaded or blobified and attached to an email.

## Under Development

**In it's current state the class supports all invite types as long as the developer
knows the components and attributes that are required for the desired invite.**

With that in mind, this class is under development. The goal is to simplify creating
calendar invites so that developers who are not familliar with the standard can
use it to create invites quickly and easily.

Presently, only event's are supported for quick and easy creation. This seems to
be the most common invite type (most client's don't even support the others).

## Default Values for Quick Event

Quick Events come with many attributes assumed. These should cover 80% of use
cases without much issue.

## Timezone

The quick event class automatically sets the timezone to UTC. This is because
SFDC stores date-times in utc so conversion is minimal. Email clients see the UTC
timezone and automatically convert it to the timezone of the recipient. This also
cuts way back on code and simplifies the serialized invite as no timezone definition
is required.

## Transparency

It is assumed that the recipient should be viewed as "busy" during the alloted time.

## Version

It is assumed the most recent version is desired.

## Class

Public

## Description

This one is a bit trickier to explain. In my testing, the standard description
field is plain text. For my use cases, I needed to be able to put links into this
field.

I found that Microsoft Outlook supports HTML descriptions but GMail does not.
However, gmail will honor Microsoft's HTML description to some extent

-- Google will display the HTML description in the email invite, but not in the 
calendar

-- Google will strip HTML from the description and display the raw text in the
calendar

-- Google will convert URL's in the calender to clikable links automatically

While I haven't tested on Mac's iCalendar, the most consistent way of providing
a description is to use Microsoft's proprietary description tag (not in the 
standard) and ignoring the standard text-description entirely (as both clients 
will prioritize this over the HTML description, the HTML description supports
plain text).

As mentioend above, this class does support using the plain text description if
required, however, only the HTML description is supported in the quickEvent
method.

# Visualforce Excample

## Controller

```
public class CalendarTestController {
    public string ci {get; set;}
    
    public CalendarTestController() {
        Set<Id> users = new Set<Id>();
        users.add(userInfo.getUserId());
        ci = CalendarInvite.quickEvent(
            'Party Time',
            '<a href="http://google.com">http://google.com</a>',
            'Friggin Everywhere',
            new Set<Id>(),
            users,
            system.now(),
            system.now().addhours(3)
        ).serialize();
    }
}
```

## Page

```
<apex:page title="event.ics" contentType="text/calendar" cache="false" 
    controller="CalendarTestController">
{!ci}
</apex:page>
```

# Email Attachment Example

```
Messaging.EmailFileAttachment invite = new Messaging.EmailFileAttachment();

invite.filename = 'invite.cls';
invite.inline = false; // note, I haven't tested email client support for true/false yet
invite.body = blob.valueOf(CalendarInvite.quickEvent(
    'Party Time',
    '<a href="http://google.com">http://google.com</a>',
    'Friggin Everywhere',
    new Set<Id>(),
    users,
    system.now(),
    system.now().addhours(3)
).serialize());
```

