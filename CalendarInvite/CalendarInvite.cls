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
    
    // Defaults are probably unecessary...
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
    
    // The actual invite
    public Component invite {
        get {
            if (invite == null) {
                invite = new Component(INVITE_NAME);
            }
            
            return invite;
        }
        
        private set;
    }
    
    public INVITE_TYPE inviteType {get; set;}

    // For the time being, use the shortcut methods.
    public CalendarInvite() {}
    
    public String serialize() {
        return invite.serialize();
    }
    
    // For quickly creating events (most common type, with most common attributes)
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
        // new Map<String, String>{LANGUAGE_NAME => DEFAULT_LANGUAGE}
        // I don't believe language is required, if we provide for summary, need to provide for loc and
        // description too
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
        
        // Grr, fails
        newEvent.attributes.put('ATTENDEES', attendees);
            
        nci.invite.components.put(INVITE_TYPE.VEVENT.name(), newEvent);
        
        return nci;
    }
    
    private static String formatDateTime(DateTime dt) {
        String result = dt.formatGMT('yyyyMMddHHmmss');
        result = result.left(8) + 'T' + result.right(6) + 'Z';
        return result;
    }
    
    /*
     * Has begin and end tags and contains a list of attributes
     * and components
     */
    public class Component {
        public String name; //BEGIN:NAME and END:NAME
        
        /* 
         * This components attributes
         * 
         * Note: Attributes could be a single attribute or a list of duplicate attributes
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