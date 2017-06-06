public class ListViewSamplePageController {
    public String allContactQuery {
        get {
            return 'SELECT FirstName, LastName, Email FROM Contact';
        }
        
        set;
    }
    
    public String myContactQuery {
        get {
            return 'SELECT FirstName, LastName, Email FROM Contact WHERE OwnerId = \'' + 
                UserInfo.getUserId() + '\'';
        }
        
        set;
    }
}