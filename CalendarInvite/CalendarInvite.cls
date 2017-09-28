public class CalendarInvite {
    private static String NEWLINE = '\r\n';
    
    // Parameter names - Note, considering enums but they 1) take more characters to use
    // and 2) don't seem to auto-complete as well as finals
    public static final string INVITE_NAME = 'VCALENDAR';
    public static final string STARTTIME_NAME = 'DTSTART';
    public static final string ENDTIME_NAME = 'DTEND';
    public static final string LOCATION_NAME = 'LOCATION';
    public static final string LANGUAGE_NAME = 'LANGUAGE';
    public static final string TRANSPARENT_NAME = 'TRANSP';
    public static final string SUMMARY_NAME = 'SUMMARY';
    public static final string ATTENDEE_NAME = 'ATTENDEE';
    public static final string ROLE_NAME = 'ROLE';
    public static final string RSVP_NAME = 'RSVP';
    public static final string COMMON_NAME = 'CN';
    public static final string CLASS_NAME = 'CLASS';
    public static final string DESCRIPTION_NAME = 'DESCRIPTION';
    public static final string FMTTYPE_NAME = 'FMTTYPE';
    public static final string DTSTAMP_NAME = 'DTSTAMP';
    public static final string UID_NAME = 'UID';
    public static final string ORGANIZER_NAME = 'ORGANIZER';
    public static final string STATUS_NAME = 'STATUS';
    public static final string SEQUENCE_NAME = 'SEQUENCE';
    public static final string PRODID_NAME = 'PRODID';
    public static final string VERSION_NAME = 'VERSION';
    public static final string TIMEZONE_NAME = 'TZ';
    public static final string EVENT_NAME = 'VEVENT';
    public static final string METHOD_NAME = 'METHOD';
    
    private static final string DEFAULT_VERSION = '2.0';
    private static final string DEFAULT_SUBJECT = 'BeyondTrust Event';
    private static final string DEFAULT_DESCRIPTION = '';
    private static final string DEFAULT_LOCATION = 'BeyondTrust';
    private static final dateTime DEFAULT_STARTTIME = system.now();
    private static final dateTime DEFAULT_ENDTIME = system.now();
    private static final string DEFAULT_LANGUAGE = 'en-us';
    private static final string DEFAULT_TRANSPARENT = 'OPAQUE';
    private static final string DEFAULT_CLASS = 'PUBLIC';
    private static final string DEFAULT_FMTTYPE = 'text/html';
    private static final string DEFAULT_TIMEZONE = '+00';
    private static final string DEFAULT_DTSTAMP = formatDateTime(system.now());
    private static final string DEFAULT_PRODID = system.URL.getSalesforceBaseUrl().getHost();
    private static final string DEFAULT_UID = formatDateTime(system.now()) + '@' + DEFAULT_PRODID;
    
    /*
     * This is where the actual invite is stored. Internal methods work on this
     * invite.
     */
    public Component invite {
        get {
            if (invite == null) {
                invite = new Component(INVITE_NAME);
            }
            
            return invite;
        }
        
        private set;
    }

    /*
     * Empty constructor. Use this to manually create the invite.
     */
    public CalendarInvite() {}
    
    /*
     * Shortcut to invite.serialize();
     */
    public String serialize() {
        return invite.serialize();
    }
    
    
    public static CalendarInvite quickEvent(string subject, string description, string location, 
        SObject recipient, DateTime startTime, DateTime endTime) {
        List<SObject> recipients = new List<SObject>{recipient};
        return quickEvent(subject, description, location, recipients, startTime, endTime, null, null);
    }
    
    public static CalendarInvite quickEvent(string subject, string description, string location, 
        List<SObject> recipients, DateTime startTime, DateTime endTime) {
        return quickEvent(subject, description, location, recipients, startTime, endTime, null, null);
    }
    
    public static CalendarInvite quickEvent(string subject, string description, string location, 
        SObject recipient, DateTime startTime, DateTime endTime, String uid, SObject organizer) {
        List<SObject> recipients = new List<SObject>{recipient};
        return quickEvent(subject, description, location, recipients, startTime, endTime, uid, organizer);
    }
    
    /*
     * Method to create a calendar invite of the type "VEVENT".
     *
     * @param String The subject of the event
     * @param String The description of the event
     * @param String The location of the event
     * @param Set<Id> A set of Ids for any contacts that should be included in the event
     * @param Set<Id> A set of Ids for any users that should be included in the event
     * @param DateTime The Starting Date/Time for the event
     * @param DateTime The Ending Date/Time for the event
     * @param String The unique ID for the invite, required for updating/canceling events. Default system.now(), recommended to use record Id
     * @param SObject A record containing a valid 'Email' and 'Name' field to set as the organizer (user, queue, contact, etc)
     * @ return CalendarInvite a new instance of a CalendarInvite class representing the event
     */
    public static CalendarInvite quickEvent(string subject, string description, string location, 
        List<SObject> recipients, DateTime startTime, DateTime endTime, String uid, SObject organizer) {
        uid = uid == null ? DEFAULT_UID : uid + '@' + DEFAULT_PRODID;
        CalendarInvite nci = new CalendarInvite();
        Component newEvent = new Component(EVENT_NAME);
        List<Attribute> attendees = new List<Attribute>();

        nci.invite.attributes.put(VERSION_NAME, new Attribute(VERSION_NAME, DEFAULT_VERSION));
        nci.invite.attributes.put(TIMEZONE_NAME, new Attribute(TIMEZONE_NAME, DEFAULT_TIMEZONE));
        nci.invite.attributes.put(PRODID_NAME, new Attribute(PRODID_NAME, DEFAULT_PRODID));
        nci.invite.attributes.put(METHOD_NAME, new CalendarInvite.Attribute(METHOD_NAME, 'REQUEST'));
        
        newEvent.attributes.put(UID_NAME, new Attribute(UID_NAME, uid));
            
        if (organizer != null) {
            Attribute tempAtt = getOrganizerAttribute(organizer);
            newEvent.attributes.put(tempAtt.name, tempAtt);
        }
        
        newEvent.attributes.put(DTSTAMP_NAME, new Attribute(DTSTAMP_NAME, DEFAULT_DTSTAMP));
        newEvent.attributes.put(CLASS_NAME, new Attribute(CLASS_NAME, DEFAULT_CLASS));
        newEvent.attributes.put(SUMMARY_NAME, new Attribute(SUMMARY_NAME, subject));
        newEvent.attributes.put(DESCRIPTION_NAME, new Attribute(DESCRIPTION_NAME, description));
        newEvent.attributes.put(LOCATION_NAME, new Attribute(LOCATION_NAME, location));
        newEvent.attributes.put(STARTTIME_NAME, new Attribute(STARTTIME_NAME, formatDateTime(starttime)));
        newEvent.attributes.put(ENDTIME_NAME, new Attribute(ENDTIME_NAME, formatDateTime(endtime)));
        newEvent.attributes.put(TRANSPARENT_NAME, new Attribute(TRANSPARENT_NAME, DEFAULT_TRANSPARENT));
        
        for (SObject so : recipients) {
            attendees.add(new Attribute(
                ATTENDEE_NAME,
                (String) so.get('email'),
                new Map<String, String> {
                    COMMON_NAME => (String) so.get('name')
                        }
            ));
        }
        
        newEvent.attributes.put('ATTENDEES', attendees);
            
        nci.invite.components.put(EVENT_NAME, newEvent);
        
        return nci;
    }
    
    /*
     * Method to cancel event identified by provied uid. I'm not entirely sure
     * if organizer is required yet. The idea is that if the invite does not contain
     * the correct organizer, the invite might be coming from someone who does not have
     * permission to edit or cancel the event. Also note, a phony DTSTART attribute is
     * added for validation purposees.
     * 
     * @param String The uid for the event to be cancled. Idealy, this is stored on the
     * record related to the event and generated via the supplied generateUID() method.
     * @param SObject The record containing a valid 'email' and 'name' field (user, queue, etc)
     * that represents the organizer of the event.
     */
    public static CalendarInvite cancelEvent(String uid, SObject organizer) {
        CalendarInvite nci = new CalendarInvite();
        Component newEvent = new Component(EVENT_NAME);
        
        if (uid != null) {
            uid += '@' + DEFAULT_PRODID;
        } else {
            throw new CalendarInviteException('Must provide UID of event to cancel');
        }
        
        nci.invite.attributes.put(VERSION_NAME, new Attribute(VERSION_NAME, DEFAULT_VERSION));
        nci.invite.attributes.put(TIMEZONE_NAME, new Attribute(TIMEZONE_NAME, DEFAULT_TIMEZONE));
        nci.invite.attributes.put(PRODID_NAME, new Attribute(PRODID_NAME, DEFAULT_PRODID));
        nci.invite.attributes.put(METHOD_NAME, new Attribute(METHOD_NAME, 'CANCEL'));
        
        newEvent.attributes.put(UID_NAME, new Attribute(UID_NAME, uid));
        newEvent.attributes.put(SEQUENCE_NAME, new Attribute(SEQUENCE_NAME, '99'));
        // Required for ics validation, not sure if this needs to match the actual event start time or not
        newEvent.attributes.put(STARTTIME_NAME, new Attribute(STARTTIME_NAME, formatDateTime(system.now())));
        
        if (organizer != null) {
            Attribute tempAtt = getOrganizerAttribute(organizer);
            newEvent.attributes.put(tempAtt.name, tempAtt);
        }
        
        newEvent.attributes.put(DTSTAMP_NAME, new Attribute(DTSTAMP_NAME, DEFAULT_DTSTAMP));
        newEvent.attributes.put(CLASS_NAME, new Attribute(CLASS_NAME, DEFAULT_CLASS));
        newEvent.attributes.put(STATUS_NAME, new Attribute(STATUS_NAME, 'CANCELLED'));
        newEvent.attributes.put(SEQUENCE_NAME, new CalendarInvite.Attribute(SEQUENCE_NAME, '99'));
        
        nci.invite.components.put(EVENT_NAME, newEvent);
        
        return nci;
    }
    
    /*
     * A method to generate a unique UID for the event. Using this method
     * provides a very unique identifier to help ensure that it is globally unique.
     * Since this method relies on date/time, it is recommended to store the uid on
     * the record it pertains to for reference at a later time (updates or cancelations)
     * 
     * @param Id The id of the record the event pertains to
     * @param Id The id of the recipient of the invite.
     * @return String A globally unique ID for the event
     */
    public static String generateUID(Id recordId, Id recipientId) {
        return (String) recordId + (String) recipientId +
            formatDateTime(system.now()) + '@' + DEFAULT_PRODID;
    }
    
    /*
     * Converts a date-time object into a standardized string:
     * Ex. 20170911T205555Z
     */
    public static String formatDateTime(DateTime dt) {
        String result = dt.formatGMT('yyyyMMddHHmmss');
        result = result.left(8) + 'T' + result.right(6) + 'Z';
        return result;
    }
    
    /*
     * Helper method to generate an attribute for the organizer since
     * this code appears more than once.
     */
    private static Attribute getOrganizerAttribute(SObject organizer) {
        Attribute result;
        
        if (organizer != null) {
            result = new Attribute(ORGANIZER_NAME, (String) organizer.get('email'), 
                new Map<String, String>{
                    COMMON_NAME => (String) organizer.get('name')
                }
            );
        }
        
        return result;
    }
    
    /*
     * The invite is a markup language file that shares many features with xml
     * A component is defined as having start and end tags that encompass nested
     * attributes (Map<String, Object>). The invite itself is a componenet, with 
     * attributes and nested components. Begin and end tags follow the format:
     * BEGIN:NAME and END:NAME
     *
     * <p> 
     * Note: The component may have more than one attribute that share a name.
     * The invite stores these as a Map<String, List<Attribute>. Most notably,
     * attendees fall under this category.
     * </p>
     */
    public class Component {
        public String name; //BEGIN:NAME and END:NAME
        
        /* 
         * This component's attributes
         * 
         * Note: Attributes could be a single attribute or a list of duplicate attributes (Attendees)
         */ 
        public Map<String, object> attributes; 
        public Map<String, Component> components;// sub componenets
        
        public Component (String name) {
            this(name, new Map<String, Object>(), new Map<String, Component>());
        }
        
        public Component (String name, Map<String, Object> attributes,
            Map<String, Component> components) {
            this.name = name;
            this.attributes = attributes;
            this.components = components;
        }
        
        public String serialize() {
            String result = '';
            
            result += 'BEGIN:' + name + NEWLINE;
            
            for (object o : attributes.values()) {
                if (o instanceof Attribute) {
                    result += ((Attribute) o).serialize() + NEWLINE;
                } else if (o instanceof List<Attribute>) {
                    for (Attribute a : (List<Attribute>) o) {
                        result += a.serialize() + NEWLINE;
                    }
                } else {
                    throw new CalendarInviteException('Attributes map contains invalid object type: ' 
                        + string.valueOf(o) + ' only CalendarInvite.Attribute and List<CalendarInvite.Attribute> are supported');
                }
            }
            
            for (Component c : components.values()) {
                result += c.serialize() + NEWLINE;
            }
            
            result += 'END:' + name;
            
            return result;
        }
    }

    /*
     * An attibute is a single line in the markup file that follows the format:
     * Name;propert=value;property=value:value or Name:value
     */
    public class Attribute {
        public String name;
        public String value;
        public Map<String, String> properties;
        
        public Attribute(String name, String value) {
            this(name, value, new Map<String, String>());
        }
        
        public Attribute(String name, String value, Map<String, String> properties) {
            this.name = name;
            this.value = value;
            this.properties = properties;
        }
        
        public String serialize() {
            String result = '';
            
            result += name;
            
            if (!properties.isEmpty()) {
                result += ';';
                
                for (String s : properties.keySet()) {
                    result += s + '=' + properties.get(s) + ';';
                }
                
                result = result.left(result.length() - 1);
            }
            
            result += ':' + value;
            
            return result;
        }
    }
    
    private class CalendarInviteException extends Exception {}
}