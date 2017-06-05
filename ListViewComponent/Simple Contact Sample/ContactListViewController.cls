/*
 * This provides the simples example of using the listViewController to
 * display a paginated list view of contacts.
 */
public class contactListViewController extends ListViewController {
    public List<Contact> contacts {
        get {
            contacts = new List<Contact>();
            
            for (SObject so : setCon.getRecords()) {
                contacts.add((Contact) so);
            }
            
            return contacts;
        }
        
        set;
    }
}