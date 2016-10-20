/******************************************************************************************************************************
* @class name      : PieChartDataWrapper
* @description     : Dedicated Wrapper Class to be created for Pie Chart.
* @test class      : BouquetCreationExtensionTest            
* @author          : Candidate
* @date            : 28/09/2016            
                    
* Modification Log :
* -----------------------------------------------------------------------------------------------------------------
* Developer                                      Date(MM/DD/YYYY)       Description
* -----------------------------------------------------------------------------------------------------------------
* Candidate                                      28/09/2016             Created.

******************************************************************************************************************************/

public class PieChartDataWrapper {
    
    public String color {get;set;}      // This is used to store color a String
    public integer quantity {get;set;}   // This is used to store Total Quantity associated to this color
    
    // This constructor is used to color and quantity values passed
    public PieChartDataWrapper(String selectedcolor, integer caluclatedQuantity) {
        color  = selectedcolor;
        quantity = caluclatedQuantity;
    }
}