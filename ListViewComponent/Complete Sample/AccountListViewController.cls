/*
 * This provides the simplest example of using the listViewController to
 * display a paginated list view of contacts.
 */
public class AccountListViewController extends ListViewController {
    /*
     * Handles typecasting generic SObjects into objects of the desired
     * type.
     */
    public List<AccountWrapper> accounts {get; set;}
    
    public override void resetRecordList() {
        accounts = new List<AccountWrapper>();
        
        for (SObject so : setCon.getRecords()) {
            accounts.add(new AccountWrapper(so));
        }
    }
    
    public List<AccountWrapper> selectedAccounts {
        get {
            selectedAccounts = new List<AccountWrapper>();
            
            for (AccountWrapper aw : accounts) {
                if (aw.selected) {
                    selectedAccounts.add(aw);
                }
            }
            
            return selectedAccounts;
        }
        
        set;
    }
    
    /*
     * Wrapper class to facilitate record selection
     */
    public class AccountWrapper {
        public Boolean selected {get; set;}
        public Account record {get; set;}
        
        public AccountWrapper (SObject so) {
            this.record = (Account) so;
            this.selected = false;
        }
    }
}