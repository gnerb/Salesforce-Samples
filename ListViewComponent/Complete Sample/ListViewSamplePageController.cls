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
    
    public String allAccountQuery {
        get {
            return 'SELECT Name, Industry, TickerSymbol FROM Account';
        }
        
        set;
    }
    
    public String myAccountQuery {
        get {
            return 'SELECT Name, Industry, TickerSymbol FROM Account WHERE OwnerId = \'' +
                UserInfo.getUserId() + '\'';
        }
        
        set;
    }
}