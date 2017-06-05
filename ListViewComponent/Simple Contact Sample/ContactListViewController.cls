/*
 * This provides the simplest example of using the listViewController to
 * display a paginated list view of contacts.
 */
public class contactListViewController extends ListViewController {
    public List<Contact> contacts {get; set;}
    
    public override resetRecordList() {
        contacts = new List<Contact>();
        
        for (SObject so : setCon.getRecords()) {
            contacts.add((Contact) so);
        }
    }
}