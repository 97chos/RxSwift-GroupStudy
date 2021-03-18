//  func buyAction(count: Int, completion: @escaping () -> Void) {
//    if self.boughtCoinsIndex == nil {
//      var totalPrice: Double = 0
//
//      self.coin
//        .take(1)
//        .map{ $0.prices?.currentPrice ?? 0 }
//        .subscribe(onNext: { price in
//          totalPrice = price * Double(count)
//        })
//        .disposed(by: bag)
//
//      self.amountData.deposit
//        .take(1)
//        .map{ price -> Double in
//          var currenTotalPrice = price
//          currenTotalPrice -= totalPrice
//          return currenTotalPrice
//        }
//        .subscribe(onNext: {
//          self.amountData.deposit.onNext($0)
//        })
//        .disposed(by: bag)
//
//      Observable.combineLatest(AD.boughtCoins, self.coin)
//        .take(1)
//        .map{ boughtList, currentCoin -> ([Coin], Coin) in
//          var list = boughtList
//          var coin = currentCoin
//
//          coin.holdingCount = count
//          coin.totalBoughtPrice = totalPrice
//          list.append(coin)
//          return (list, coin)
//        }
//        .observe(on: MainScheduler.asyncInstance)
//        .subscribe(onNext: {
//          self.coin.accept($1)
//          AD.boughtCoins.accept($0)
//          self.boughtCoinsIndex = $0.firstIndex(of: $1)
//        })
//        .disposed(by: bag)
//    } else {
//      var totalPrice: Double = 0
//      var boughtCoinList: [Coin] = []
//      guard let index = self.boughtCoinsIndex else {
//        return
//      }
//
//      self.coin
//        .map{ ($0.prices?.currentPrice ?? 0) * Double(count) }
//        .take(1)
//        .subscribe(onNext: {
//          totalPrice = $0
//        })
//        .disposed(by: bag)
//
//      self.amountData.deposit
//        .take(1)
//        .map{
//          var currentTotalPrice = $0
//          currentTotalPrice -= totalPrice
//          return currentTotalPrice
//        }
//        .observe(on: MainScheduler.asyncInstance)
//        .subscribe(onNext: {
//          self.amountData.deposit.onNext($0)
//        })
//        .disposed(by: bag)
//
//      self.amountData.boughtCoins
//        .take(1)
//        .map{
//          var coinList = $0
//          coinList[index].holdingCount += count
//          coinList[index].totalBoughtPrice += totalPrice
//          return coinList
//        }
//        .do(onNext:{ boughtCoinList = $0 })
//        .subscribe(onNext: {
//          self.amountData.boughtCoins.accept($0)
//        })
//        .disposed(by: bag)
//
//      self.coin.accept(boughtCoinList[index])
//    }
//    completion()
//  }
//
//
//  func sellAction(count: Int, completion: () -> Void) {
//    var boughtList: [Coin] = []
//    var indexCoin: Coin?
//    var coinIndex: Int?
//    var remainingCount: Int = 0
//    var totalRemainingPrice: Double = 0
//    var totalCellPrice: Double = 0
//
//    AD.boughtCoins
//      .subscribe(onNext: {
//        boughtList = $0
//        guard let index = self.boughtCoinsIndex else {
//          return
//        }
//        coinIndex = index
//        indexCoin = boughtList[index]
//        remainingCount = (indexCoin?.holdingCount ?? 0) - count
//      })
//      .disposed(by: bag)
//
//    self.coin
//      .take(1)
//      .map{ $0.prices?.currentPrice ?? 0 }
//      .subscribe(onNext: { price in
//        totalRemainingPrice = price * Double(remainingCount)
//      })
//      .disposed(by: bag)
//
//    self.coin
//      .take(1)
//      .map{ $0.prices?.currentPrice ?? 0 }
//      .subscribe(onNext: { price in
//        totalCellPrice = price * Double(count)
//      })
//      .disposed(by: bag)
//
//    self.amountData.deposit
//      .map{
//        var deposit = $0
//        deposit += totalCellPrice
//        return deposit
//      }
//      .take(1)
//      .observe(on: MainScheduler.asyncInstance)
//      .subscribe(onNext: {
//        self.amountData.deposit.onNext($0)
//      })
//      .disposed(by: bag)
//
//    self.amountData.boughtCoins
//      .take(1)
//      .map{ list -> [Coin] in
//        var coinList = list
//        guard let index = coinIndex else { return [] }
//        coinList[index].totalBoughtPrice -= max(coinList[index].totalBoughtPrice - totalRemainingPrice, 0)
//        coinList[index].holdingCount -= count
//        return coinList
//      }
//      .observe(on: MainScheduler.asyncInstance)
//      .do{
//        guard let index = coinIndex else { return }
//        self.coin.accept($0[index])
//      }
//      .map{
//        var coinList = $0
//        guard let index = coinIndex else { return [] }
//        if coinList[index].holdingCount == 0 {
//          coinList.remove(at: index)
//        }
//        return coinList
//      }
//      .subscribe(onNext: {
//        self.amountData.boughtCoins.accept($0)
//      })
//      .disposed(by: bag)
//
//    completion()
//  }
