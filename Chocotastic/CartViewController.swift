/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

class CartViewController: UIViewController {
  
  @IBOutlet private var checkoutButton: UIButton!
  @IBOutlet private var totalItemsLabel: UILabel!
  @IBOutlet private var totalCostLabel: UILabel!
  @IBOutlet weak var cartStackView: UIStackView!
  
  var dataChocolate: [String] = ["a", "b", "c"]
  
  //MARK: - View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Cart"
    configureFromCart()
    addView()
  }
  
  private func addView() {
//    cartStackView.addArrangedSubview(view)
//    let vc = CartViewController()
//    vc.dataChocolate = ["a", "b", "c"]
//    self.navigationController?.pushViewController(vc, animated: <#T##Bool#>)
    
    let cart = ShoppingCart.sharedCart
    let choco = cart.chocolates
    
    let a = choco.asObservable()
      .subscribe(onNext: {
          chocolates in
//            print("chocolates")
//            print(chocolates)
        
        self.appendCell(value: "Nama Coklat", qty: 5)
        
        let country = chocolates.map { (choco) -> String in
          print(choco)
          return choco.countryName
        }
        
//        let title = product.map { (product) -> String in
//          return product.name ?? ""
//        }
      }
    )
    
//    dataChocolate.forEach { (value) in
//    }
  }
  
  private func appendCell(value: String, qty: Int) {
    let cellView = UIView(frame: CGRect.zero)
    self.view.addSubview(cellView)
    cartCardStyle(view: cellView)
    
    let label = UILabel(frame: CGRect.zero)
    cellView.addSubview(label)
    
    let labelQty = UILabel(frame: CGRect.zero)
    cellView.addSubview(labelQty)
    
    self.labelNameStyle(label: label, text: value, parent: cellView)
    self.labelQtyStyle(label: labelQty, qty: qty, parent: cellView)
    
    cartStackView.addArrangedSubview(cellView)
  }
  
  private func configureFromCart() {
    guard checkoutButton != nil else {
      //UI has not been instantiated yet. Bail!
      return
    }
    
    let cart = ShoppingCart.sharedCart
    totalItemsLabel.text = cart.itemCountString()
    
    let cost = cart.totalCost()
    totalCostLabel.text = CurrencyFormatter.dollarsFormatter.rw_string(from: cost)
    
    //Disable checkout if there's nothing to check out with
    checkoutButton.isEnabled = (cost > 0)
  }
  
  @IBAction func reset() {
    ShoppingCart.sharedCart.chocolates.value = []
    let _ = navigationController?.popViewController(animated: true)
  }
  
  private func cartCardStyle(view: UIView) {
    view.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    view.layer.borderWidth = 1
    view.layer.cornerRadius = 4
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: 72).isActive = true
    view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16).isActive = true
    view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16).isActive = true
  }
  
  private func labelNameStyle(label: UILabel, text: String, parent: UIView) {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = #colorLiteral(red: 0.3051282465, green: 0.7462322116, blue: 0.356926471, alpha: 1)
    label.text = text
    label.font = label.font.withSize(16)
    label.centerYAnchor.constraint(equalTo: parent.centerYAnchor, constant: -8).isActive = true
    label.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 16).isActive = true
  }
  
  private func labelQtyStyle(label: UILabel, qty: Int, parent: UIView) {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = String(qty)
    label.textColor = #colorLiteral(red: 0.3051282465, green: 0.7462322116, blue: 0.356926471, alpha: 1)
    label.font = label.font.withSize(20)
    label.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -16).isActive = true
    label.centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
  }
}
