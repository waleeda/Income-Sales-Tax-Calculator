//
//  Model.swift
//  Income & Sales Tax
//
//  Created by waleed azhar on 2017-04-07.
//  Copyright © 2017 waleed azhar. All rights reserved.
//

import Foundation
//typealiases for readability
typealias Dollars = Float

typealias Rate = Float
typealias Tax = Rate

typealias SalesTax = Tax
typealias Harmonized = SalesTax

typealias Saving = Rate
typealias Interest = Rate

typealias IncomeBracket = (min:Dollars, max:Dollars, rate:Tax)
typealias IncomeBrackets = [IncomeBracket]
typealias TaxCollector = (IncomeBracket) -> Dollars


// a single household, earning income, defined by yearly income & saving rate
struct HouseHold{
    
    let income:Dollars
    
    let savingRate:Saving
    
    init(income: Dollars, savingRate: Saving) {
        guard income > 0, savingRate >= 0, savingRate <= 1 else {
            fatalError("income must be >0; savingRate must be within [0,1]")
        }
        self.income = income
        self.savingRate = savingRate
    }
}
//computer properties
extension HouseHold{
    
    var incomeTaxOwed: Dollars {
        return Ontario.incomeTaxOwed(by: self) + Federal.incomeTaxOwed(by: self)
    }
    
    var yearlySavings: Dollars {
        return (self.income - self.incomeTaxOwed) * self.savingRate
    }
    
    var disposableIncome: Dollars {
        return income - (incomeTaxOwed + yearlySavings)
    }
    
    var disposableIncomePaidAsSalesTax: Dollars {
        return Ontario.salesTaxOwed(by: self)
    }
    
    var taxesPaid: Dollars{
        return self.incomeTaxOwed + self.disposableIncomePaidAsSalesTax
    }
    
    var averageTaxRate :Rate {
        return taxesPaid / income
    }
    
    var disposableIncomeAfterSalesTax: Dollars {
        return disposableIncome - disposableIncomePaidAsSalesTax
    }
    
    var monthlyTakeHome: Dollars {
        return disposableIncome / 12.0
    }
}


// function to calculate total income tax owed
func calculateTax(on houseHold: HouseHold) -> TaxCollector{
    
    let income = houseHold.income
    
    return { bracket in
        
        guard income >= bracket.min else {
            return 0
        }
        
        var pre:Float = bracket.min, post:Float = 0
        
        if income > bracket.max {
            post = income - bracket.max
        }
        
        return ((income - (pre + post)) * bracket.rate)
    }
}

//define a government
protocol Government{
    
    static var taxBrackets:[IncomeBracket] {get}
    
    static func incomeTaxOwed(by houseHold: HouseHold) -> Dollars
    
}

struct Federal:Government{
    
    internal static let taxBrackets: IncomeBrackets = [(0,45916,0.15),
                                                       (45916,91831,0.205),
                                                       (91831,142353,0.26),
                                                       (142353,202800,0.29),
                                                       (202800,Float.infinity,0.33)]
    
    static func incomeTaxOwed(by houseHold: HouseHold) -> Dollars {
        
        let accountant = calculateTax(on: houseHold)
        
        return Federal.taxBrackets.reduce(0.0) { (result, bracket) -> Dollars in
            return result + accountant(bracket)
        }
        
    }
    
}

struct Ontario:Government{
    
    static let HST:Harmonized = 0.13
    
    internal static let taxBrackets: IncomeBrackets = [(0,42201,0.0505),
                                                       (42201,84404,0.0915),
                                                       (84404,150000,0.1116),
                                                       (150000,220000,0.1216),
                                                       (220000,Float.infinity,0.1316)]
    
    static func incomeTaxOwed(by houseHold: HouseHold) -> Dollars {
        
        let taxman:TaxCollector = calculateTax(on: houseHold)
        
        return Ontario.taxBrackets.reduce(0.0) { (result, bracket) -> Dollars in
            return result + taxman(bracket)
        }
        
    }
    
    static func salesTaxOwed(by houseHold: HouseHold) -> Dollars{
        return houseHold.disposableIncome * Ontario.HST
    }
}

//example
