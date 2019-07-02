public without sharing class ContractorSearchController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStateMap(){
        Map<String, Set<String>> stateToCity = new Map<String, Set<String>>();

        for (AggregateResult ar : [
            SELECT MailingState, MailingCity
            FROM Contact
            WHERE MailingState != null
                AND MailingCity != null
            GROUP BY MailingState, MailingCity
            ORDER BY MailingState ASC, MailingCity ASC
        ]) {
            String mailingState = (String) ar.get('MailingState');
            String mailingCity = (String) ar.get('MailingCity');

            if (!stateToCity.containsKey(mailingState)) {
                stateToCity.put(mailingState, new Set<String>());
            }

            stateToCity.get(mailingState).add(mailingCity);
        }

        return stateToCity;
    }

    // returns contractors in the given city/state
    // To do: add more search options
    @AuraEnabled
    public static List<Contact> getContractors(String state, String city) {
        String escapedState = string.escapeSingleQuotes(state);
        String escapedCity = string.escapeSingleQuotes(city);
        
        return [
            SELECT Id, Name, Email, Phone
            FROM Contact
            WHERE RecordType.DeveloperName = 'Contractor'
                AND MailingState = :escapedState
                AND MailingCity = :escapedCity
        ];
    }
}