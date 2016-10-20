/******************************************************************************************************************************
* @class name      : BouquetCreationExtension
* @description     : This class is used as an extension for BouquetCreation Page.
*                       1. Responsible for Creation of Bouquet, Blooms records.
*                       2. Pagination for list of combination of Bloom Qantity and Products.
*                       3. Charting has done for the set of Color of Flowers being used.
* @test class      : BouquetCreationExtensionTest            
* @author          : Candidate
* @date            : 25/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      25/09/2016             Created.

******************************************************************************************************************************/

public with sharing class BouquetCreationExtension_V1 {
    
    // 
    public String selectedFamily                            {get;set;}  // To store selected Product Family for filtering
    public Bouquet__c bouquetObj                            {get;set;}  // To store selected Bouquet record
    private Map<Id,BloomProductWrapper> productIdVsWrapperMap;          // For storing all possible Products Key is Product Id and Value is BloomProductWrapper
    private List<BloomProductWrapper> bloomProductWrapperList;          // To display pagination results
    
    // Charting Varibales
    public Boolean displaySummaryChart                      {get;set;}  // To store if summary chart has to be displayed or not
    public List<PieChartDataWrapper> summaryChartDataList   {get;set;}  // Chart data has retained 
    public String flowerColorCodeString                     {get;set;}  // Hexa Color Code to be provided Pie Chart 
    private Map<String,String> colorVsColorCodeMap;                     // Retaining Hexa Decimal codes for respective colors
    private Double totalBouquetCost;                                    // Evaluate Cost of Bouquet
    public String bouquetCostLabel                          {get;set;}  // Broadcasting Bouquet Cose with Dollar Sign
    
    // Pagination Variables
    private Integer totalPages;                                         // This variable caluclates total possible Page based on PAGE_SIZE 
    private Integer totalRecords = 0;                                   // Total number of available eachProducts 
    private static final Integer PAGE_SIZE = 5;                         // Default number of record on each page
    
    /**
     *      @method name:   BouquetCreationExtension
     *      @description:   Constructor     
     *      @param      :   ApexPages.StandardController
    */  
    public BouquetCreationExtension_V1(ApexPages.StandardController controller) {
        
        //Used to get current record of Bouquet    
        bouquetObj  = (Bouquet__c)controller.getRecord();
    
        //fetch all eachProducts and intitalize data in BloomProductWrapper 
        //where Key -- ProductId record Id and Value -- BloomProductWrapper
        init();
    }
    
    /**
     *      @method name:   BouquetCreationExtension
     *      @description:   Querying all the data based different parameters for PageLoad.
     *                          1. Querying Products to shown on page
     *                          2. maps formation for further evaluation of Business Logics
     *                          3. Invoking Pie Chart Data population method
     *      @param      :   NA
    */
    private void init(){
        
        Set<Id> productIds                      = new Set<Id>();
        List<Product2> productList              = new List<Product2>();
        List<Bloom__c> bloomList                = new List<Bloom__c>();
        Map<Id,Bloom__c> mapProductIdVsBloom    = new Map<Id,Bloom__c>();
        colorVsColorCodeMap                     = new Map<String,String>();
        productIdVsWrapperMap                   = new Map<Id,BloomProductWrapper>();
       
        // Used to query all possible Flowers based on selected category selectedFamily
        productList = QueryUtilityClass.getProductRecords(bouquetObj.Id, selectedFamily);
        
        // While Editing a Bouquet get all Bid Record associated to Bouquet
        // and initialize data in the map against each Flower
        if(bouquetObj.Id != null) {
            bloomList = QueryUtilityClass.getBloomRecords(bouquetObj.Id);
            
            // Map creation for Product Id to Bloom, It will be helpfull for dedication
            // of respective Flower colors to Pie Chart.
            for(Bloom__c eachBloom : bloomList) {
                mapProductIdVsBloom.put(eachBloom.Flower__c,eachBloom);
            }     
        }
       
       //Based on all possible Product records available intialize data in productIdVsWrapperMap
       for(Product2 eachProduct : productList) {
            
            // To retain colors with respective Color Code for each product.
            colorVsColorCodeMap.put(eachProduct.Color__c,eachProduct.HTML_Color_Code__c); 
            
            if(mapProductIdVsBloom.ContainsKey(eachProduct.Id)) {
                productIdVsWrapperMap.put(eachProduct.Id,new BloomProductWrapper(eachProduct,mapProductIdVsBloom.get(eachProduct.Id)));
            }
            else{
                productIdVsWrapperMap.put(eachProduct.Id,new BloomProductWrapper(eachProduct));     
            }   
        }
        
        // To evalute Chart Data on page load.
        evaluateSummaryChartData();
    }
    
    /**
     *      @description :   Method to get StandardSetController for Product and Bloom    
     *      @return      :   ApexPages.StandardSetController  
     */
    public ApexPages.StandardSetController productSetController {
        get {
            
            if(productSetController == null) { 
                
                //Used to query all possible Item records based on Donation Id and selectedFamily            
                productSetController = new ApexPages.StandardSetController(QueryUtilityClass.getProductRecords(bouquetObj.Id, selectedFamily));
                // sets the number of records in each page set and get ResultSize i.e store in total records
                productSetController.setPageSize(PAGE_SIZE);
                totalRecords = productSetController.getResultSize();
            
            }
            return productSetController;    
           
        }
        set;    
    }
    
    /**
     *      @method name :  getBloomProductWrapperList  
     *      @description :  This method returns list of Products and Blooms for current page using standard set controller
     *                      and then creates BloomProductWrapperList before passing it to the visualfore page.      
     *      @param       :  None           
     *      @return      :  List<BloomProductWrapper>          
     */
    public List<BloomProductWrapper> getBloomProductWrapperList() {
        bloomProductWrapperList = new List<BloomProductWrapper>();
        for(Product2 eachProduct : (List<Product2>)productSetController.getRecords()) {
           if(productIdVsWrapperMap.containsKey(eachProduct.Id)){
             bloomProductWrapperList.add(productIdVsWrapperMap.get(eachProduct.Id));       
           } 
        }
        return bloomProductWrapperList;
    }
    
    /**
     *      @description :   Method invokes while changing the picklist values
     *      @return      :   PageReference  
     */
    public PageReference fetchItemsByCategory(){
        // Set productSetController to Null so that Getter method will query Items based on selected flower family
        evaluateSummaryChartData();
        productSetController = null;
        return null;
    }
    
    /**
     *      @description :   Fetch all the Families based on values stored on Family picklist on Product object
     *      @return      :   ApexPages.StandardSetController  
     */
    public List<SelectOption> getCategories() {
        
        List<SelectOption> options                  = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult      = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple              = fieldResult.getPicklistValues();
        
        options.add(new SelectOption('--Any Type--','--Any Type--'));
     
        for(Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
         
        return options;
    }
    
    /**
     *      @method name :   saveBouquet  
     *      @description :   This method create new Agenda or Update existing one with all changes made by user.
                             It also create,update or delete related agenda workshop records based on the changes made by user while paginating/fiterting. 
                             This method redirects user to previous page when records are saved successfully and shows error message if any.     
     *      @param       :   None            
     *      @return      :   PageReference           
     */
    public PageReference saveBouquet(){
        Savepoint sp = Database.setSavepoint(); 
        try {
               
            List<Bloom__c> bloomsToUpsert           = new List<Bloom__c>();
            List<Bloom__c> bloomsToDelete           = new List<Bloom__c>();

            // upserts changes to New to existing donation  
            upsert bouquetObj;           

            // Creates or Updates or Deletes Bids Records based on Bid Amount specified                   
            for(BloomProductWrapper eachBloomWrap : productIdVsWrapperMap.Values()) {
                Bloom__c bloomRecord = new Bloom__c();  

                if(eachBloomWrap.bloomObj != null && eachBloomWrap.bloomObj.Quantity__c != 0){

                    if(eachBloomWrap.bloomObj.Id != null) {
                        bloomRecord.Id = eachBloomWrap.bloomObj.Id;  
                    }

                    bloomRecord.Bouquet__c = bouquetObj.Id;
                    bloomRecord.Flower__c = eachBloomWrap.productObj.Id;  
                    bloomRecord.Quantity__c = eachBloomWrap.bloomObj.Quantity__c;

                    bloomsToUpsert.add(bloomRecord);
                }

                if(eachBloomWrap.bloomObj != null && eachBloomWrap.bloomObj.Quantity__c == 0 && eachBloomWrap.bloomObj.Id != null){
                    bloomsToDelete.add(eachBloomWrap.bloomObj);
                }
            }

            if(!bloomsToUpsert.isEmpty()){
                upsert bloomsToUpsert;
            }

            if(!bloomsToDelete.isEmpty()){
                delete bloomsToDelete; 
            } 

            // redirects to Bouquet detail page 
            return new PageReference('/'+bouquetObj.Id);
        }
        catch(DmlException e) {
            // Rollbacks all the changes if any dml exceptions and displays error message on the UI
            bouquetObj = bouquetObj.clone();
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,e.getDmlMessage(0))); 
        }
        catch(Exception e){
            // Rollbacks all the changes if any exceptions and displays error message on the UI
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,e.getMessage()));
        }
        return null;     
    }  
    
    /**
     *      @method name :   evaluateSummaryChartData
     *      @description :   This method is used to generate data for pie chart Colors with respect to thier counts
     *                       Calculating total cost of Bouquet based Quantity and Flowers cost.
     *      @param       :   None          
     *      @return      :   list<PieChartDataWrapper>         
     */
    public List<PieChartDataWrapper> evaluateSummaryChartData() {

        summaryChartDataList                            = new List<PieChartDataWrapper >();
        Map<String,Integer> colorVsFlowerQuantityMap    = new Map<String,Integer>();
        displaySummaryChart                             = false;
        flowerColorCodeString                           = '';
        totalBouquetCost                                = 0;

        // Caluclates quantity for each color and stores in colorVsFlowerQuantityMap
        for(BloomProductWrapper bloomWrap : productIdVsWrapperMap.Values()) {
            
            if(Integer.valueOf(bloomWrap.bloomObj.Quantity__c) > 0){
                if(colorVsFlowerQuantityMap.containsKey(bloomWrap.productObj.Color__c)){
                    colorVsFlowerQuantityMap.put(bloomWrap.productObj.Color__c, colorVsFlowerQuantityMap.get(bloomWrap.productObj.Color__c)+Integer.valueOf(bloomWrap.bloomObj.Quantity__c));
                }
                else{
                    colorVsFlowerQuantityMap.put(bloomWrap.productObj.Color__c , Integer.valueOf(bloomWrap.bloomObj.Quantity__c));
                }
                totalBouquetCost += (bloomWrap.bloomObj.Quantity__c * bloomWrap.productObj.Cost__c);
            }
        
        }
        
        bouquetCostLabel = '$ ' + String.ValueOf(totalBouquetCost);
        system.debug('@@colorVsFlowerQuantityMap@@'+colorVsFlowerQuantityMap);

        if(colorVsFlowerQuantityMap.size() > 0) {
            
            for(String color : colorVsFlowerQuantityMap.KeySet()) {
                summaryChartDataList.add(new PieChartDataWrapper(color,colorVsFlowerQuantityMap.get(color)));    
            }
            system.debug('@@summaryChartDataList@@'+summaryChartDataList);
            
            displaySummaryChart = true;
            
            if((summaryChartDataList.size() > 0 ) && (summaryChartDataList.size() != null)){
                if(colorVsColorCodeMap.size() > 0){
                    for(PieChartDataWrapper loopvar : summaryChartDataList){
                        if(colorVsColorCodeMap.ContainsKey(loopvar.Color)){
                                // flowerColorCodeString.add(prdObj.HTML_Color_Code__c);
                                flowerColorCodeString += (colorVsColorCodeMap.get(loopvar.Color)+ ',');                      
                                
                        }
                    }
                system.debug('@@HTML_Color_Code__c@@'+flowerColorCodeString);
                }
            }
        
        }
        return summaryChartDataList;
    }
    
    // Utilized to show the count of pages appearing for Pagination.
    public Integer getTotalPages() {
        totalPages = (math.mod(totalRecords, PAGE_SIZE) > 0) ? ( ( totalRecords/ PAGE_SIZE) + 1) : ( totalRecords/ PAGE_SIZE ); 
        return totalPages;
    }
    
    // Indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return productSetController.getHasNext();
        }
        set;
    }

    // Indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return productSetController.getHasPrevious();
        }
        set;
    }

    // Returns the page number of the current page set
    public Integer pageNumber {
        get {
            return productSetController.getPageNumber();
        }
        set;
    }
    
    // returns the first page of records
    public void first() {
        evaluateSummaryChartData();
        productSetController.first();
    }

    // returns the last page of records
    public void last() {
        evaluateSummaryChartData();
        productSetController.last();
    }

    // returns the previous page of records
    public void previous() {
        evaluateSummaryChartData();
        productSetController.previous();  
    }

    // returns the next page of records
    public void next() {
        evaluateSummaryChartData();
        productSetController.next();
    }

}