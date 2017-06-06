/*
 * This provides the simplest example of using the listViewController to
 * display a paginated list view of contacts.
 */
public class contactListViewController extends ListViewController {
    /*
     * Handles typecasting generic SObjects into objects of the desired
     * type.
     */
    public List<Contact> contacts {
        get {
            return (List<Contact>) recordList;
        }
        
        set;
    }
}