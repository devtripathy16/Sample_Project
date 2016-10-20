/******************************************************************************************************************************
* @class name      : BloomTriggerHandler
* @description     : This class is used for 
*                       1. Update of Inventory used on Product2 Object.
*                       2. Update of Color Text on the Lead Object. 
* @test class      : BloomTriggerHandlerTest            
* @author          : Candidate
* @date            : 22/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      22/09/2016             Created.

******************************************************************************************************************************/

public with sharing class BloomTriggerHandler {
    
    /**
     *      @method name:   updateProductInventory
     *      @description:   Update of Inventory used on Product2 Object, Most User Color on Lead Object     
     *      @param      :   List<Bloom__c>, Map<Id,Bloom__c>
    */  
    public static void updateProductInventory(List<Bloom__c> bloomList, Map<Id,Bloom__c> oldBloomMap) {
            
        // These variables are used for updating Product/Lead 
        Set<Id> relatedIds                              = new Set<Id>();
        Map<Id,String> mapLeadIdToMostUsedColor         = new Map<Id,String>();
        Map<Id,Double> mapProductIdToInventoryUsed      = new Map<Id,Double>();
        List<Product2> listProductToUpdate              = new List<Product2>();
        List<Lead> listLeadToUpdate                     = new List<Lead>();
        
        // Iterate over the first parameter bloom Records (Trigger.new/Trigger.old) 
        // Store all Product/Lead record Ids related to Bloom.
        if(bloomList.size() > 0){
            for(Bloom__c eachBloom : bloomList) {
                relatedIds.add(eachBloom.Flower__c);
                relatedIds.add(eachBloom.Bouquet__c);
                
                if(oldBloomMap != null) {
                   if(eachBloom.Flower__c != oldBloomMap.get(eachBloom.Id).Flower__c) {
                      relatedIds.add(oldBloomMap.get(eachBloom.Id).Flower__c);
                    }
                   if(eachBloom.Bouquet__c != oldBloomMap.get(eachBloom.Id).Bouquet__c) {
                      relatedIds.add(oldBloomMap.get(eachBloom.Id).Bouquet__c);
                   }                  
                }
            }
        }
        
             
        //Aggregate query is used to store Sum of Quantity of Flowers
        //associated to each Boquet in a map mapProductIdToInventoryUsed
        for(AggregateResult eachBloom  : [SELECT Flower__c flower, SUM(Quantity__c) sumQuantity
                                            FROM Bloom__c WHERE Flower__c IN :relatedIds
                                            GROUP BY Flower__c]) {
            
            // underlying map will be utilised later to evaluated entered 
            mapProductIdToInventoryUsed.put((Id)eachBloom.get('flower'),(Double)eachBloom.get('sumQuantity'));
            // list will ensure to update products with thier relevenat quantities.
            listProductToUpdate.add(new Product2(Id = String.valueOf(eachBloom.get('flower')) , Inventory_Used__c = Integer.valueOf(eachBloom.get('sumQuantity'))));           
        }
        
        // Logic to make Inventory User as 0, when Bloom Record is deleted belonging to Flower.
        // It will be checked for last Bloom record deletion for any specific flower.
        // This scenario is not queried as Data is not available after deleteion for AggregateResult
        if(Trigger.Isdelete){
            for(Bloom__c eachBloom : bloomList){
                if(!mapProductIdToInventoryUsed.containsKey(eachBloom.Flower__c)){
                    listProductToUpdate.add(new Product2(Id = eachBloom.Flower__c , Inventory_Used__c = 0));  
                }
            }
        }
        
        
        // Retrival of all the Lead id into a set
        for(Bouquet__c eachBouquet : [SELECT Id, Customer__c
                                        FROM Bouquet__c
                                        WHERE Id IN :relatedIds]){
            relatedIds.add(eachBouquet.Customer__c);
        }
            
        //Aggregate query is used to store Sum of Quantity of Flowers
        //associated to each Boquet in a map mapProductIdToInventoryUsed
        for(AggregateResult eachBloom  : [SELECT Flower__r.Color__c color, Bouquet__r.Customer__c customer,  SUM(Quantity__c) sumQuantity
                                    FROM Bloom__c WHERE Bouquet__r.Customer__c IN :relatedIds
                                    GROUP BY  Bouquet__r.Customer__c, Flower__r.Color__c
                                    ORDER BY SUM(Quantity__c) DESC, Flower__r.Color__c ASC ]) {
            
            // This condition will make sure to pick Highest Color quantity Flower
            // Considering Color Sort as well in case highest quantities are same 
            // two diff colors.
            if(!mapLeadIdToMostUsedColor.containsKey(String.valueOf(eachBloom.get('customer')))){
                mapLeadIdToMostUsedColor.put(String.valueOf(eachBloom.get('customer')), String.valueOf(eachBloom.get('color')));
            }                           
        }
        
        for(Id eachCustomerId : mapLeadIdToMostUsedColor.keySet()){
            listLeadToUpdate.add(new Lead(Id = eachCustomerId, Most_Used_Color__c = mapLeadIdToMostUsedColor.get(eachCustomerId)));         
        }
        
        // These variables are used to ids of Successful records and error messages
        Set<Id> successProductIds               = new Set<Id>();
        Set<Id> successLeadIds                  = new Set<Id>();
        Set<String> errorProducts               = new Set<String>();
        Set<String> errorLeads                  = new Set<String>();
          
        if(listProductToUpdate.size()>0) {
            Database.saveResult[] saveResultItems  = Database.update(listProductToUpdate,false);
                for (Database.saveResult sr : saveResultItems) {
                    if(sr.isSuccess()){
                        successProductIds.add(sr.getId());
                }
                else{
                    for(Database.Error err : sr.getErrors()) {
                        errorProducts.add(err.getMessage());
                    } 
                }
            }
        }
        
        if(listLeadToUpdate.size()>0) {
            Database.saveResult[] saveResultItems  = Database.update(listLeadToUpdate,false);
                for (Database.saveResult sr : saveResultItems) {
                    if(sr.isSuccess()){
                        successLeadIds.add(sr.getId());
                }
                else{
                    for(Database.Error err : sr.getErrors()) {
                        errorLeads.add(err.getMessage());
                    } 
                }
            }
        }
        
        // to broadcast errors of related Blooms records,
        // where we failed to update Product and Lead records
        if(errorProducts.size() > 0 || errorLeads.size() > 0){
            for(Bloom__c eachBloom: bloomList) {
                if(!successProductIds.contains(eachBloom.Flower__c)){
                    for(String err: errorProducts) {
                        eachBloom.addError(err);
                     }          
                }
                if(!successLeadIds.contains(eachBloom.Bouquet__r.Customer__c)){
                    for(String err: errorLeads) { 
                        eachBloom.addError(err); 
                     }         
                }
            }
       } 
          
    }
}