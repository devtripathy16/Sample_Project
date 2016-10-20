//*****************************************************************************************************
// Name         : TestDataUtility 
// Created by   : Candidate
// Description  : This class is used for preparing Test Data on various objects
//                like User,Lead,Bouquet,Product2,Bloom.
//******************************************************************************************************

public class TestDataUtility {
    
    //This method can be used to generate random number based 
    // on the upperLimit parameter provided
    public static Integer randomWithLimit(Integer upperLimit){
        Integer rand = Math.round(Math.random()*1000);
        return Math.mod(rand, upperLimit);
    }
    
    //This method prepares Test Data for users based on parameters 
    // number of users and profileId provided
    public static List<User> createTestUser(Integer numOfUsers,Id profileId) {         
       List<User> userList= new List<User >();
       
       // Random number is generated to maintain unique values   
       Integer randomNumber = randomWithLimit(4789954);
         
       for(Integer n = 0; n < numOfUsers ; n++) {
            User u= new User();
            u.LastName = 'Test User Last Name' +n+randomNumber;
            u.Username = 'TestUserqaz123@test.com'+n+randomNumber;
            u.Email =  'UserEmailwsx456@test.com'+n+randomNumber;
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.LocaleSidKey = 'en_US';
            u.Alias = 'TALIAS9';
            u.IsActive = true;
            u.EmailEncodingKey = 'UTF-8';
            u.LanguageLocaleKey = 'en_US';
            u.ProfileId = profileId; 
            userList.add(u); 
       }
       
      return userList;
    }
    
    // This method is used to preapre Test Data for Leads creation
    // based on the number of Leads provided
    public static List<Lead> createTestLeads(Integer numOfLeads) {    
      List<Lead> LeadList = new List<Lead>();
      
      // Random number is generated to maintain unique values
      Integer randomNumber = randomWithLimit(679895);
      
      for(Integer n = 0; n < numOfLeads ; n++) {
          Lead customer = new Lead(LastName='Test Lead'+n+randomNumber,Company='Test Company'+n+randomNumber,Status='Open'); 
          LeadList.add(customer);
      }
      return LeadList;  
    }
    
        // This method prepares each Bouquet for Leads provided
    public static List<Bouquet__c> createTestBouquets(List<Lead> leadList) {    
      List<Bouquet__c> bouquetList = new List<Bouquet__c>();
      
      for(Lead customer : LeadList) {
          Bouquet__c boq = new Bouquet__c(Customer__c=customer.Id,Deliver_To__c=customer.LastName+customer.Id,Delivery_Date__c=System.Today()+7,Message__c='Test Message'+customer.Id);
          bouquetList.add(boq);
      }
      return bouquetList;  
    }

    // This method is used to prepare a Test Data for Products(Flowers) based on 
    // quantities and flowers provided
    public static List<Product2> createTestProducts(Integer numOfProducts,String color) {    
      List<Product2> productList = new List<Product2>();
       
       for(Integer n = 0; n < numOfProducts; n++) {
           Product2 flower = new Product2(Name = 'Test Flower'+n+color,Color__c = color,Initial_Inventory__c = 1000);
                                           
           productList.add(flower);    
       }
      
      return productList;  
    }

    // This method is used prepare Test data for Blooms for Different Products(Flowers) 
    // to a Bouquet provided   
    public static List<Bloom__c> createTestBloom(Id bouquetId , List<Product2> productList) {
      List<Bloom__c> bloomList = new List<Bloom__c>();
      // integer count =0;
         for(Product2 flower : productList) {
              // count++;
              Bloom__c bloom = new Bloom__c(Bouquet__c = bouquetId , Flower__c = flower.Id , Quantity__c  = 10);
              bloomList.add(bloom);
         }     
      return bloomList;
    }
    
    // This method is useful for preparing a Test Data a Single bloom record
    // based on the bouquetId,flowerId,bloomQuantity provided
    public static Bloom__c createTestSinglebloom(Id bouquetId, Id flowerId,Double bloomQuantity) {
       Bloom__c bloom = new Bloom__c(Bouquet__c = bouquetId , Flower__c = flowerId , Quantity__c  = bloomQuantity);
       return bloom;
    }
}