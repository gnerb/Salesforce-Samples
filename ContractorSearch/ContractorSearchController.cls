public without sharing class ContractorSearchController {
    private static Schema.DescribeSObjectResult contactDescribe;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName;
    private static String contractorRecordTypeId;

    static {
        contactDescribe = Schema.SObjectType.Contact;
        rtMapByName = contactDescribe.getRecordTypeInfosByName();
        contractorRecordTypeId = rtMapByName.get('Contractor').getRecordTypeId();
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStateMap(){
        system.debug(contractorRecordTypeId);
        Map<String, Set<String>> stateToCity = new Map<String, Set<String>>();

        for (AggregateResult ar : [
            SELECT MailingState, MailingCity
            FROM Contact
            WHERE MailingState != null
                AND MailingCity != null
                AND RecordTypeId = :contractorRecordTypeId
            GROUP BY MailingState, MailingCity
            ORDER BY MailingState ASC, MailingCity ASC
        ]) {
            system.debug(string.valueOf(ar));
            String mailingState = (String) ar.get('MailingState');
            String mailingCity = (String) ar.get('MailingCity');

            if (!stateToCity.containsKey(mailingState)) {
                stateToCity.put(mailingState, new Set<String>());
            }

            stateToCity.get(mailingState).add(mailingCity);
        }

        return stateToCity;
    }

    @AuraEnabled
    public static List<Contact> getContractors(
        String state, String city, Boolean osha, Boolean vehicle, Boolean drugscreen,
        Boolean wwid, Boolean backgroundcheck, String skillLevel, String trade
    ) {
        String escapedState = string.escapeSingleQuotes(state);
        String escapedCity = string.escapeSingleQuotes(city);
        
        
        // Need to make query more dynamic...
        Query query = new Query('SELECT Id, Name, Email, Phone FROM Contact');
        
        query.addFilter('RecordTypeId', contractorRecordTypeId);
        query.addFilter('MailingState', state);
        query.addFilter('MailingCity', city);
        query.addFilter('gnsf__HasDrugScreen__c', drugscreen);
        query.addFilter('gnsf__HasOSHACertification__c', osha);
        query.addFilter('gnsf__HasVehicle__c', vehicle);
        query.addFilter('gnsf__HasWWID__c', wwid);
        query.addFilter('gnsf__HasBackgroundCheck__c', backgroundcheck);
        query.addFilter('gnsf__Trade__c', trade);
        query.addFilter('gnsf__SkillLevel__c', skillLevel);
        system.debug(query.soql);

        return database.query(query.soql);
    }

    // Will need to update to include a way to work with ratings using >
    // Will need to be able to handle different value types
    

    private class Query {
        public String soql {get; private set;}

        public Query(String baseString) {
            this.soql = baseString;
        }

        private void addFilter(String fieldName, object value) {
            if (value != null && fieldName != null && this.soql != null) {
                String escapedName = string.escapeSingleQuotes(fieldName);

                if (this.soql.indexOfIgnoreCase('WHERE') == -1) {
                    this.soql += ' WHERE';
                }  else {
                    this.soql += ' AND';
                }

                switch on getType(value) {
                    when 'String' {
                        String escapedString = string.escapeSingleQuotes((String) value);
                        this.soql += ' ' + escapedName + '=\'' + escapedString + '\'';
                    }
                    when 'Boolean' {
                        Boolean convertedValue = (Boolean) value;

                        if (convertedValue) {
                            this.soql += ' ' + escapedName + '=' + convertedValue;
                        } else {
                            // Remove ' AND' since we do not want to add the field
                            this.soql = this.soql.left(this.soql.length() - 4);
                        }
                    }
                    when else {
                        system.debug(fieldName);
                        system.debug(value);
                    }
                }
            }
        }

        private string getType(Object o) {
            if(o==null) return '';              // we can't say much about null with our current techniques
            if(o instanceof Boolean)            return 'Boolean';
            if(o instanceof String)             return 'String';
            return 'Unhandled Object';                    // actually we can't detect maps and sets and maps
        }
    }
}