/*
 * This provides the simplest example of using the listViewController to
 * display a paginated list view of contacts.
 */
public class contactListViewController extends ListViewController {
    /*
     * Handles typecasting generic SObjects into objects of the desired
     * type.
     */
    public List<ContactWrapper> contacts {get; set;}
    
    public override void resetRecordList() {
        contacts = new List<ContactWrapper>();
        
        for (SObject so : setCon.getRecords()) {
            contacts.add(new ContactWrapper(so));
        }
    }
    
    public List<ContactWrapper> selectedContacts {
        get {
            selectedContacts = new List<ContactWrapper>();
            
            for (ContactWrapper cw : contacts) {
                if (cw.selected) {
                    selectedContacts.add(cw);
                }
            }
            
            return selectedContacts;
        }
        
        set;
    }
    
    /*
     * Wrapper class to facilitate record selection
     */
    public class ContactWrapper {
        public Boolean selected {get; set;}
        public Contact record {get; set;}
        
        public ContactWrapper (SObject so) {
            this.record = (Contact) so;
            this.selected = false;
        }
    }
}