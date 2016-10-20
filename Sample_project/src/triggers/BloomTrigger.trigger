/******************************************************************************************************************************
* @Trigger name    : BloomTrigger
* @description     : This class is used as an extension for BouquetCreation Page.
* @test class      : BloomTriggerHandlerTest            
* @author          : Candidate
* @date            : 20/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      20/09/2016             Created.

******************************************************************************************************************************/

trigger BloomTrigger on Bloom__c (after insert,after undelete, after update, after delete) {
   
    // Perform Operations on Insert/Update/Undelete Events   
    if((Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate) && Trigger.isAfter) {
        BloomTriggerHandler.updateProductInventory(trigger.new,trigger.oldMap);
    }
    
    // Perform Operations on Delete Events   
    if(Trigger.IsDelete){
        BloomTriggerHandler.updateProductInventory(trigger.Old,null);
    }
    
}