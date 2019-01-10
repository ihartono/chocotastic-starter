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

class BillingInfoViewController: UIViewController {
  
  @IBOutlet private var creditCardNumberTextField: ValidatingTextField!
  @IBOutlet private var creditCardImageView: UIImageView!
  @IBOutlet private var expirationDateTextField: ValidatingTextField!
  @IBOutlet private var cvvTextField: ValidatingTextField!
  @IBOutlet private var purchaseButton: UIButton!
  
  private let cardType: Variable<CardType> = Variable(.Unknown)
  private let disposeBag = DisposeBag()
  private let throttleInterval = 0.1
  
  //MARK: - View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "💳 Info"
    
    setupCardImageDisplay()
    setupTextChangeHandling()
    
    hahaha()
    self.creditCardNumberTextField.keyboardType = UIKeyboardType.numberPad
    self.expirationDateTextField.keyboardType = UIKeyboardType.numberPad
    self.cvvTextField.keyboardType = UIKeyboardType.numberPad
  }
  
  func hahaha () {
    let a = creditCardNumberTextField.rx
      .text
      .map { $0 ?? "" }

      a.subscribe(onNext: { element in
        print(element)
      })
      .disposed(by: disposeBag)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let identifier = identifierForSegue(segue: segue)
    switch identifier {
    case .PurchaseSuccess:
      guard let destination = segue.destination as? ChocolateIsComingViewController else {
        assertionFailure("Couldn't get chocolate is coming VC!")
        return
      }
      
      destination.cardType = cardType.value
    }
  }
  
  //MARK: - RX Setup
  private func setupCardImageDisplay() {
    cardType
      .asObservable()
      .subscribe(onNext: {
        cardType in
          self.creditCardImageView.image = cardType.image
      })
    .disposed(by: disposeBag)
  }
  
  private func setupTextChangeHandling() {
    /**
     1. return the contents of the text fieldas an Observable value
     2. You throttle the input so that the validation you're setting up is only run based on the interval defined above.
        The scheduler parameter is more advanced concept, but the short version is that it's tied to a thread.
        Since you want to keep everything on the main thread, use MainScheduler
     3. You transform the throttle input by applying it to validate(cardText:), already provided for you by the class.
        If the card input is valid, the ultimate value of the boolean being observed will be true
     4. You take the Observable value you've created and subscribe to it, updating the validity of the text field based on the incoming value
     5. You add the resulting Disposable to the disposeBag
     */
    
    let creditCardValid = creditCardNumberTextField
      .rx
      .text //1
      .throttle(throttleInterval, scheduler: MainScheduler.instance) //2
      .map {self.validate(cardText: $0 ?? "") } //3

    creditCardValid
      .subscribe(onNext: { self.creditCardNumberTextField.valid = $0 }) //4
      .disposed(by: disposeBag) //5
    
    
    let expirationValid = expirationDateTextField
      .rx
      .text
      .throttle(throttleInterval, scheduler: MainScheduler.instance)
      .map { self.validate(expirationDateText: $0 ?? "") }

    expirationValid
      .subscribe(onNext: { self.expirationDateTextField.valid = $0 })
      .disposed(by: disposeBag)
    
    
    let cvvValid = cvvTextField
      .rx
      .text
      .map { self.validate(cvvText: $0 ?? "") }

    cvvValid
      .subscribe(onNext: { self.cvvTextField.valid = $0 })
      .disposed(by: disposeBag)

    let everythingValid = Observable
      .combineLatest(creditCardValid, expirationValid, cvvValid) {
        $0 && $1 && $2 // All must be true
    }
    
    everythingValid
      .bind(to: purchaseButton.rx.isEnabled)
      .disposed(by: disposeBag)
  }

  //MARK: - Validation methods
  
  func validate(cardText: String) -> Bool {
    let noWhitespace = cardText.rw_removeSpaces()
    
    updateCardType(using: noWhitespace)
    formatCardNumber(using: noWhitespace)
    advanceIfNecessary(noSpacesCardNumber: noWhitespace)
    
    guard cardType.value != .Unknown else {
      //Definitely not valid if the type is unknown.
      return false
    }
    
    guard noWhitespace.rw_isLuhnValid() else {
      //Failed luhn validation
      return false
    }
    
    return noWhitespace.count == self.cardType.value.expectedDigits
  }
  
  func validate(expirationDateText expiration: String) -> Bool {
    let strippedSlashExpiration = expiration.rw_removeSlash()
    
    formatExpirationDate(using: strippedSlashExpiration)
    advanceIfNecessary(expirationNoSpacesOrSlash:  strippedSlashExpiration)
    
    return strippedSlashExpiration.rw_isValidExpirationDate()
  }
  
  func validate(cvvText cvv: String) -> Bool {
    guard cvv.rw_allCharactersAreNumbers() else {
      //Someone snuck a letter in here.
      return false
    }
    dismissIfNecessary(cvv: cvv)
    return cvv.count == self.cardType.value.cvvDigits
  }
  
  //MARK: Single-serve helper functions
  
  private func updateCardType(using noSpacesNumber: String) {
    cardType.value = CardType.fromString(string: noSpacesNumber)
  }
  
  private func formatCardNumber(using noSpacesCardNumber: String) {
    creditCardNumberTextField.text = self.cardType.value.format(noSpaces: noSpacesCardNumber)
  }
  
  func advanceIfNecessary(noSpacesCardNumber: String) {
    if noSpacesCardNumber.count == self.cardType.value.expectedDigits {
      self.expirationDateTextField.becomeFirstResponder()
    }
  }
  
  func formatExpirationDate(using expirationNoSpacesOrSlash: String) {
    expirationDateTextField.text = expirationNoSpacesOrSlash.rw_addSlash()
  }
  
  func advanceIfNecessary(expirationNoSpacesOrSlash: String) {
    if expirationNoSpacesOrSlash.count == 6 { //mmyyyy
      self.cvvTextField.becomeFirstResponder()
    }
  }
  
  func dismissIfNecessary(cvv: String) {
    if cvv.count == self.cardType.value.cvvDigits {
      let _ = self.cvvTextField.resignFirstResponder()
    }
  }
}

// MARK: - SegueHandler 
extension BillingInfoViewController: SegueHandler {
  enum SegueIdentifier: String {
    case
    PurchaseSuccess
  }
}
