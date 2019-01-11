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
import RxSwift
import RxCocoa

class ChocolatesOfTheWorldViewController: UIViewController {
  
  @IBOutlet private var cartButton: UIBarButtonItem!
  @IBOutlet private var tableView: UITableView!
//  let europeanChocolates = Chocolate.ofEurope
  let europeanChocolates = Observable.just(Chocolate.ofEurope)
  
  let disposeBag = DisposeBag()
  
  //MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chocolate!!!"
    
    setupCartObserver()
    setupCellConfiguration()
    setupCellTapHandling()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  //MARK: Rx Setup
  private func setupCartObserver() {
    /**
     1. grab chocolates variable as an Observable
     2. Subscribe to find out about changes to the Observable status, will update title every time the value changes
        The incoming parameter to the closure is the new value of your Observable, and you’ll keep getting these notifications
        until you either unsubscribe or your subscription is disposed. What you get back from this method is an Observer conforming to Disposable.
     3. Add the Observer from previous step to disposeBag to ensure that your subscription is disposed of when the subscribing object is deallocated.
     */
    
    //1
    ShoppingCart.sharedCart.chocolates.asObservable()
      .subscribe(onNext: { //2
        chocolates in
        self.cartButton.title = "\(chocolates.count) \u{1f36b}"
      })
      .disposed(by: disposeBag) //3
  }
  
  private func setupCellConfiguration() {
    /**
     1. You call bind(to: _) to associate the europeanChocolates observable with the code that should get executed for each row in the table row
     2. by calling rx, you are able to access the rxCocoa extensions for whatever class you call it on - in this case, a UITableView
     3. You call the rx method items(cellIdentifier: cellType:), passing in the cell identifier and the class of the cell type you want to use
        This allows the rx framework to call the dequeing method that would normally be called if your table view still had its original delegates
     4. You pass in a block to be executed for each new item. You'll get back information about the row, the chocolate at that row, and the cell,
        making it super-easy to configure the cell
     5. You take the Disposable returned by bind(to: _) and add it to the disposeBag
     */
    
    //1
    europeanChocolates
      .bind(to:tableView
        .rx //2
        .items(cellIdentifier: ChocolateCell.Identifier, cellType: ChocolateCell.self)) { //3
            row, chocolate, cell in
            cell.configureWithChocolate(chocolate: chocolate) //4
    }
    .disposed(by: disposeBag) //5
  }
  
  private func setupCellTapHandling() {
    /**
     1. You call the table view's reactive extension's modelSelected(_:) function, passing in the Chocolate model to get the proper type of item back.
        This returns as Observable
     2. Taking the Observable, you call subscribe(onNext:), passing in a trailing closure of what should be done
        any time a model is selected (i.e., a cell is tapped)
     3. Within the trailing closure passed to subscribe(onNext:), you add the selected chocolate to the cart
     4. also in the closure, you make sure that the tapped row is deselected
     5. subscribe(onNext:) returns a Disposable. You add that disposable to the disposeBag
     */
    
    tableView
      .rx
      .modelSelected(Chocolate.self) //1
      .subscribe(onNext: { //2
        chocolate in
          ShoppingCart.sharedCart.chocolates.value.append(chocolate) //3
        
        if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
          self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
        } //4
      })
      .disposed(by: disposeBag) //5
  }
}

// MARK: - SegueHandler
extension ChocolatesOfTheWorldViewController: SegueHandler {
  
  enum SegueIdentifier: String {
    case
    GoToCart
  }
}
