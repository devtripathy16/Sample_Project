/******************************************************************************************************************************
* @class name      : QueryUtilityClass
* @description     : This class is used for Retruning
*                       1. Query for products to be displayed on screen.
*                       2. Query Blooms of a specified Bouquet. 
* @test class      : BloomTriggerHandlerTest            
* @author          : Candidate
* @date            : 22/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      22/09/2016             Created.

******************************************************************************************************************************/

public class QueryUtilityClass {
        
    //This method is used to retrieve Item records from Product2 Object
    //based on the bouquetId and selectedCategory provided
    public static List<Product2> getProductRecords(String bouquetId, String selectedCategory) {
        
        String query = '';
        String categoryFilter = '';
        String sortingClause = '';
        String finalQuery = '';
        List<Id> listFlowerId=new List<Id>();
        
        // Retrieving Flower Ids for edit scenarios. It will contain inactive Product as well
        // If it is being utilised by underlying bouquet previously.
        for(Bloom__c b:[SELECT Flower__c FROM Bloom__c WHERE Bouquet__c =: bouquetId]){
            listFlowerId.add(b.Flower__c);
        }
        
        query = 'Select Id,Name,Family,HTML_Color_Code__c,Inventory_Remaining__c,Inventory_Used__c,IsActive,Color__c, Cost__c '+
                        ' From Product2 ';
        
        
        if(bouquetId == null){
           query  += ' WHERE IsActive = TRUE ';
        }
        else{
           query  += ' WHERE (IsActive = TRUE OR Id IN: listFlowerId) ';
        }
        
        // If category filter is selected then query will be formed in such a way that it retrieves
        // only those Products(Flowers) records where particular category is selected
        if(String.isNotBlank(selectedCategory) && !selectedCategory.equalsIgnoreCase('--Any Type--')){
            categoryFilter = ' Family = \'' + selectedCategory+ '\'';
                query +=' AND ' + categoryFilter;   
            
        }
        
        // this sorting clause is used to sort records based on the 
        // Cost and further with Color. 
        sortingClause = ' ORDER BY Cost__c, Color__c ASC ';
        
        finalQuery = query + sortingClause;
        
        return Database.Query(finalQuery);
    }
    
    // This method is used to return Bloom Record on Bloom__c Object
    // based on the bouquetId record Id provided
    public static List<Bloom__c> getBloomRecords(Id bouquetId) {
       List<Bloom__c> bloomRecordsList = [SELECT Id,Name,Quantity__c,Flower__c,
                                            Bouquet__c from Bloom__c where Flower__c != null
                                            AND Bouquet__c = : bouquetId  
                                            Limit : Limits.getLimitQueryRows()];
        return bloomRecordsList;
    }  

}