/*
 * The page controller stores the query to be passed to the component.
 */
public class ListViewSamplePageController {
    public String contactQuery {
        get {
            return 'SELECT Name FROM Contact';
        }
        
        set;
    }
}