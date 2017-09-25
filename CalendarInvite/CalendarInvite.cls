public class CalendarInvite {
    private static String NEWLINE = '\n';
    
    // Parameter names - Note, converting to enums for strict enforcement
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
    public static final string DESCRIPTION_NAME = 'X-ALT-DESC';
    public static final string FMTTYPE_NAME = 'FMTTYPE';
    
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
    
    public enum INVITE_TYPE {VEVENT, VJOURNAL, VTODO}
    public enum INVITE_ATTRIBUTE {TZ, VERSION}
    
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
     * Empty constructor. Use this to manually creat the invite.
     */
    public CalendarInvite() {}
    
    /*
     * Shortcut to invite.serialize();
     */
    public String serialize() {
        return invite.serialize();
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
     * @ return CalendarInvite a new instance of a CalendarInvite class representing the event
     */
    public static CalendarInvite quickEvent(string subject, string description, string location, 
        Set<Id> contactList, Set<Id> userList, DateTime startTime, 
        DateTime endTime) {
        CalendarInvite nci = new CalendarInvite();
        Component newEvent = new Component(INVITE_TYPE.VEVENT.name());
        List<Attribute> attendees = new List<Attribute>();
            
        nci.invite.attributes.put(INVITE_ATTRIBUTE.VERSION.name(), 
            new Attribute(INVITE_ATTRIBUTE.VERSION.name(), DEFAULT_VERSION));
        nci.invite.attributes.put(INVITE_ATTRIBUTE.TZ.name(), 
            new Attribute(INVITE_ATTRIBUTE.TZ.name(), DEFAULT_TIMEZONE));
        
        newEvent.attributes.put(CLASS_NAME, new Attribute(CLASS_NAME, DEFAULT_CLASS));
        newEvent.attributes.put(SUMMARY_NAME, new Attribute(SUMMARY_NAME, subject));
        newEvent.attributes.put(DESCRIPTION_NAME, new Attribute(DESCRIPTION_NAME, description, new Map<String, String>{
            FMTTYPE_NAME => DEFAULT_FMTTYPE
        }));
        newEvent.attributes.put(LOCATION_NAME, new Attribute(LOCATION_NAME, location));
        newEvent.attributes.put(STARTTIME_NAME, new Attribute(STARTTIME_NAME, formatDateTime(starttime)));
        newEvent.attributes.put(ENDTIME_NAME, new Attribute(ENDTIME_NAME, formatDateTime(endtime)));
        newEvent.attributes.put(TRANSPARENT_NAME, new Attribute(TRANSPARENT_NAME, DEFAULT_TRANSPARENT));
            
        for (Contact c : [SELECT Name, Email FROM Contact WHERE Id IN :contactList]) {
            attendees.add(new Attribute(
            	ATTENDEE_NAME,
                c.email,
                new Map<String, String> {
                    COMMON_NAME => c.name
                }
            ));
        }
            
        for (User u : [SELECT Name, Email FROM User WHERE Id IN :UserList]) {
            attendees.add(new Attribute(
            	ATTENDEE_NAME,
                u.email,
                new Map<String, String> {
                    COMMON_NAME => u.name
                }
            ));
        }
        
        newEvent.attributes.put('ATTENDEES', attendees);
            
        nci.invite.components.put(INVITE_TYPE.VEVENT.name(), newEvent);
        
        return nci;
    }
    
    /*
     * Converts a date-time object into a standardized string:
     * Ex. 20170911T205555Z
     */
    private static String formatDateTime(DateTime dt) {
        String result = dt.formatGMT('yyyyMMddHHmmss');
        result = result.left(8) + 'T' + result.right(6) + 'Z';
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