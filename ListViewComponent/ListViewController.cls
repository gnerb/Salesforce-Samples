public virtual class ListViewController {
    // Constants
    private final Integer cookieExpiration = 22592000;
    private final Integer defaultPageSize = 25;
    private final String pageSizeCookieName = 'pageSize';
    
    // Properties with standard getters/setters
    private String oldQuery {get; set;} // Used to determine if the query changges
    
    // Transient properties (cookies cannot be stored in the view state)
    private transient Map<String, Cookie> cookieMap;
    private transient Cookie pageSizeCookie;
    
    // Properties with Custom getters/setters
    
    /*
     * Stores the query passed to the component via it's attribute and assign it
     * to the internal query variable.
     *
     * <p>
     * This unbinds query from the component's attribute. SFDC has a unique behavior
     * where the setter for the attribute (called with assignTo) fires more than once.
     * This behavior often results in the setter firing after attempting to update the
     * variable (for instance, when adding in an order by clause for sorting) erasing
     * the change. Unbinding the attribute from the internal query allows for updating
     * the query interally to change the sort order or add a LIKE clause for searching.
     * </p>
     *
     * <p>
     * If the component is re-rendered, the query resests to what was passed to the
     * component via the attribute (allowing for an easy method for resetting the 
     * sort order or removing the LIKE clause).
     * </p>
     *
     * <p>
     * Lastly, using the setter ensures that if there is a valid change to the
     * query attribute, the internal query tracker is updated and the list view
     * will reflect the new data.
     * </p>
     */
    public String queryAttr {
        get;
        
        set {
            queryAttr = value;
            
            if (queryAttr != oldQuery || query == null) {
                query = queryAttr;
                oldQuery = queryAttr;
            }
        }
    }
    
    /*
     * The internal query used throughout the component for most operations.
     *
     * <p>
     * When the setter for this variable is called, the standard set controller
     * is rebuilt automatically.
     * </p>
     */
    public String query {
        get;
        
        set {
            query = value;
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        }
    }
    
    /*
     * The standard set controller instantiation that controls the pagination for
     * the listView. When this variable is reconstructed, the recordList is rebuilt.
     */
    public ApexPages.StandardSetController setCon {
        get;
        
        set {
            setCon = value;
            setCon.setPageSize(pageSize);
            resetRecordList();
        }
    }
    
    /*
     * Manages the desired number of records to be displayed in the list view at one
     * time.
     *
     * <p>
     * The page size preference is stored in a cookie so that it persists across 
     * sessions.
     * </p>
     *
     * <p>
     * When this variable is set, it updates the cookie (or creates a new one).
     * </p>
     */
    public Integer pageSize {
        get {
            pageSize = integer.valueOf(getPageSizeCookie().getValue());
            return pageSize;
        }
        
        set {
            pageSize = value;
            pageSizeCookie = new Cookie('pageSize', string.valueOf(pageSize), null, cookieExpiration, false);
            getCookieMap().put('pageSize', pageSizeCookie);
            ApexPages.currentPage().setCookies(cookieMap.values());
            setConPageSize(pageSize);
        }
    }
    
    /*
     * A String to keep track of the sort direction (ASC or DESC)
     */
    public String sortDir {
        get {
            if (sortDir == null) {
                if (query != null) {
                    if (query.indexOf('ASC') >= 0) {
                        sortDir = 'ASC';
                    } else if (query.indexOf('DESC') >= 0) {
                        sortDir = 'DESC';
                    }
                } else {
                    sortDir = null;
                }
            }
            
            return sortDir;
        }
        
        set;
    }
    
    /*
     * Manages the sorting functionality.
     *
     * <p>
     * If the field is null, attempt to get the sort field form the query.
     * If the query contains no sort field, the query is either not sorted
     * or sortField has been set already and should contain the correct data;
     * either way, return sortField.
     * </p>
     *
     * <p>
     * If setting sortfield, update the query to include the new field and sort
     * direction.
     * </p>
     *
     * <p>
     * If the field does not change but the setter is called, change the sort
     * direction. If it has changed, default to ASC order.
     * </p>
     */
    public String sortField {
        get {
            if (sortField == null) {
                Integer locStart = query.indexOf('ORDER BY');
                
                if (locStart >= 0) {
                    String queryEnd = query.subString(locStart + 9);
                    Integer locEnd = queryEnd.indexOf(' ');
                    
                    if (locEnd > 0) {
                        sortField = queryEnd.subString(0, locEnd);
                    }
                }
            }
            
            return sortField;
        }
        
        set {
            String tempQuery;
            Integer loc;
            
            if (!String.isEmpty(value)) {
                if (value == sortField) { // Field has not changed
                    if (sortDir == 'ASC') {
                        sortDir = 'DESC';
                    } else {
                        sortDir = 'ASC';
                    }
                } else { // The value has changed
                    sortDir = 'ASC';
                }
                
                sortField = value;
                
                // Note: We don't work on query directl as setting query will trigger
                // setCon to be re-built. We will set query at the end.
                tempQuery = query;             
                loc = tempQuery.indexOf('ORDER BY');   
                
                if (loc > 0) {
                    tempQuery = tempQuery.left(loc);
                    tempQuery = tempQuery.trim();
                }
                
                tempQuery = tempQuery + ' ORDER BY ' + sortField + ' ' + sortDir + ' NULLS LAST';
                query = tempQuery;
            }
        }
    }
    
    /*
     * Used to force a refresh of the list view.
     *
     * <p>
     * Provided as an easy way to create a refresh button on the VF page.
     * Ex. <apex:commandLink value="refresh">
     * <apex:param value="true" assignTo="{!refreshList}/>
     * </apex:commandLink>
     * </p>
     */
    public boolean refreshList {
        get;
        
        set {
            refreshList = value;
            
            if (refreshList == true) {
                refreshList = false;
                query = query;
            }
        }
    }
    
    // Transient getters/setters
    
    /*
     * Gets the pages current cookies
     */
    @TestVisible
    private Map<String, Cookie> getCookieMap() {
        cookieMap = ApexPages.currentPage().getCookies();
        
        return cookieMap;
    }
    
    /*
     * Gets the page size cookie if it exists. If it does not exist,
     * create the default cookie.
     */
    private Cookie getPageSizeCookie() {
        if (getCookieMap() != null) {
            pageSizeCookie = cookieMap.get(pageSizeCookieName);
        }
        
        if (pageSizeCookie == null) {
            pageSizeCookie = new Cookie(pageSizeCookieName, string.valueOf(defaultPageSize), null, cookieExpiration, false);
            cookieMap.put(pageSizeCookieName, pageSizeCookie);
            ApexPages.currentPage().setCookies(cookieMap.values());
        }
        
        return pageSizeCookie;
    }
    
    // Methods
    
    /*
     * Resets the recordlist that is actually displayed to the page.
     *
     * <p>
     * Often times with list views in VF you will need to wrap your records
     * in a custom class to allow for selecting records. Because of this,
     * setCon.getRecords is not used to display the records to the VF page.
     * Instead, this class allows the developer to create his/her own record list
     * to be displayed. This method runs logic that should be used to convert or
     * wrap the records as needed for display to the page.
     * </p>
     */
    public virtual void resetRecordList() {}
    
    // SetCon overrides
    // Calls resetRecordList after every setCon action
    
    /*
     * Override the default next() method of setCon
     */
    public void setConNext() {
        setCon.next();
        resetRecordList();
    }
    
    /*
     * Override the default prev() method of setCon
     */
    public void setConPrev() {
        setCon.previous();
        resetRecordList();
    }
    
    /*
     * Override the default setpageSize() method of setCon
     */
    public void setConPageSize(integer newSize) {
        setCon.setPageSize(newSize);
        resetRecordList();
    }
}