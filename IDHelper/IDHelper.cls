public class IDHelper {
    public static Map<String, ProfileIds__c> profileIds;
    public static Map<String, RecordTypeIds__c> recordTypeIds;
    
    static {
        profileIds = ProfileIds__c.getAll();
        recordTypeIds = RecordTypeIds__c.getAll();
    }
    
    /*
     * Record Type Ids
     */
    public static RecordTypeIds__c getRecordType(String name, String sObjectType) {
        List<String> hashParams = new List<String>();
        
        hashParams.add(name);
        hashParams.add(sObjectType);
        
        String hash = generateHash(hashParams);
        
        RecordTypeIds__c result = recordTypeIds.get(hash);
        
        if (result == null) {
            rebuildProfileIdCache();
            
            result = recordTypeIds.get(hash);
            
            if (result == null) {
                throw new IDHelperException('Profile does not exist: ' + name);
            }
        }
        
        return result;
    }
    
    private static void reBuildRecordTypeIdCachce() {
        clearRecordTypeIdCache();
        CacheRecordTypeIds();
    }
    
    private static void clearRecordTypeIdCache() {
        delete [SELECT Id FROM RecordTypeIds__c];
        recordTypeIds = null;
    }
    
    public static void cacheRecordTypeIds() {
        Map<String, RecordTypeIds__c> result = new Map<String, RecordTypeIds__c>();
        Integer key = 0;
        
        for (RecordType rt : [
            SELECT Id, Name, SObjectType
            FROM RecordType
        ]) {
            List<String> hashParams = new List<String>();
            
            hashParams.add(rt.Name);
            hashParams.add(rt.SObjectType);
            
            String hash = generateHash(hashParams);
            
            result.put(hash, new RecordTypeIds__c(
                Name = hash,
                Id__c = rt.Id,
                Name__c = rt.Name,
                SObjectType__c = rt.SOBjectType
            ));
        }
        
        insert result.values();
        recordTypeIds = result;
    }
    
    
    /*
     * Profile Ids
     */
    public static ProfileIds__c getProfile(String name) {
        ProfileIds__c result = profileIds.get(
            generateHash(name)
        );
        
        if (result == null) {
            rebuildProfileIdCache();
            
            result = profileIds.get(
                generateHash(name)
            );
            
            if (result == null) {
                throw new IDHelperException('Profile does not exist: ' + Name);
            }
        }
        
        return result;
    }
    
    private static void rebuildProfileIdCache() {
        clearProfileIdCache();
        cacheProfileIds();
    }
    
    private static void clearProfileIdCache() {
        delete [SELECT Id FROM ProfileIds__c];
        profileIds = null;
    }
    
    private static void cacheProfileIds() {
        Map<String, ProfileIds__c> result = new Map<String, ProfileIds__c>();
        Integer key = 0;
        
        for (Profile p : [
            SELECT Id, Name
            FROM Profile
        ]) {
            String hash = generateHash(p.Name);
            
            result.put(hash, new ProfileIds__c(
                Name = hash,
                Id__c = p.Id,
                Name__c = p.Name
            ));
        }
        
        insert result.values();
        profileIds = result;
    }
    
    /*
     * Gneric Methods
     */
    
    private static String generateHash(String param) {
        return generateHash(new List<String>{param});
    }
    
    private static String generateHash(List<String> params) {
        String result;
        
        for (String s : params) {
            result = result + s;
        }
        
        result = EncodingUtil.convertToHex(
            Crypto.generateDigest(
                'MD5',
                blob.valueOf(result)
            )
        );
        
        return result;
    }
    
    private class IDHelperException extends Exception {}
}