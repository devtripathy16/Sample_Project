/******************************************************************************************************************************
* @class name      : BloomProductWrapper
* @description     : This class is used to Store Data from Bloom and Product Object.
* @test class      : BouquetCreationExtensionTest            
* @author          : Candidate
* @date            : 25/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      25/09/2016             Created.

******************************************************************************************************************************/

public class BloomProductWrapper {
    public Bloom__c bloomObj    {get;set;}          // This is used to store data relevant for Bloom Object
    public Product2 productObj  {get;set;}          // This is used to store data relevant to Product Object
    
    //This constructor does not accept Bloom record 
    //as we do not have Bloom's Quantity initially,
    //it will be defaulted to zero
    public BloomProductWrapper(Product2 productRecord){
       productObj           = productRecord;
       bloomObj             = new Bloom__c();
       bloomObj.Quantity__c = 0; 
    }
    
    //This Constructor is used to store both instances productRecord and bloomRecord
    public BloomProductWrapper(Product2 productRecord , Bloom__c bloomRecord){
       productObj           = productRecord;
       bloomObj             = bloomRecord; 
    }
}