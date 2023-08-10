import UIKit
import Combine


var cancelBag = Set<AnyCancellable>()

// MARK: - Just

func exampleJust() {
  Just(12)
    .delay(for: 2, scheduler: DispatchQueue.main)
    .sink { value in
      print(value)
    }
    .store(in: &cancelBag)
}

// MARK: - Create array to publisher

func exampleValue() {
  
  [1, 2, 3, 4, 5]
    .publisher
    .filter { $0.isMultiple(of: 2) == false }
    .map { $0 * $0 }
    .sink { value in
      print(value)
    }
    .store(in: &cancelBag)
}

// MARK: - publisher Zip

func publisherZip() {
  let even = [2, 4, 6, 8, 10].publisher
  let odd = [1, 3, 5, 7, 9].publisher
  
  Publishers.Zip(even, odd)
    .sink { even, odd in
      print(even, odd)
    }
    .store(in: &cancelBag)
}

// MARK: - combineLatest

func combineLatest() {
  let even = [2, 4, 6, 8, 10].publisher
  let odd = [1, 3, 5, 7, 9].publisher
  
  Publishers.CombineLatest(even, odd)
    .sink { even, odd in
      print(even, odd)
    }
    .store(in: &cancelBag)
}


// MARK: - Merge Publishers

func mergePublishers() {
  let even = [2, 4, 6, 8, 10].publisher
  let odd = [1, 3, 5, 7, 9].publisher
  
  Publishers.Merge(even, odd)
    .sink { value in
      print(value)
    }
    .store(in: &cancelBag)
}



// MARK: - Timer Publisher

func timerPublisher() {
  let random = Timer.publish(every: 1, on: .main, in: .default)
    .autoconnect()
    .map { _ in Int.random(in: 0..<20) }
    
  random.sink { value in
    print("timer \(value)")
  }
  .store(in: &cancelBag)
}

// MARK: - Share Publisher

func sharePublisher() {
  let random = Timer.publish(every: 1, on: .main, in: .default)
    .autoconnect()
    .map { _ in Int.random(in: 0..<20) }
    .share()
    
  random.sink { value in
    print("Example1 \(value)")
  }
  .store(in: &cancelBag)
  
  random.sink { value in
    print("Example2 \(value)")
  }
  .store(in: &cancelBag)
}

// MARK: - Convert completion handler to combine

func convertAsync(_ completion: @escaping (Int) -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    completion(Int.random(in: 1..<100))
  }
}

func convertAsyncToCombine() {
  let coverted = Future<_, Never> { result in
    convertAsync { number in
      result(.success(number))
    }
  }
  // It will reference a same publisher, number of times you create, when you use reference `coverted`
  
  Future<_, Never> { result in
    convertAsync { number in
      result(.success(number))
    }
  }
  .sink { print("Converted result A: \($0)")}
  .store(in: &cancelBag)
  
  Future<_, Never> { result in
    convertAsync { number in
      result(.success(number))
    }
  }
  .sink { print("Converted result B: \($0)")}
  .store(in: &cancelBag)
}

// MARK: - Defer

func deferExamples() {
  let legacyAsync = Deferred {
    Future<_, Never> { result in
      convertAsync { number in
        result(.success(number))
      }
    }
  }
  
  legacyAsync
    .sink { print("Converted result A: \($0)")}
    .store(in: &cancelBag)
  
  legacyAsync
    .sink { print("Converted result B: \($0)")}
    .store(in: &cancelBag)
}

// MARK: - Loops

func repeatedValues(_ completion: @escaping (Int) -> Void) {
  for i in 1...10 {
    DispatchQueue.main.asyncAfter(deadline: .now() + (3 * Double(i))) {
      completion(Int.random(in: 1..<100))
    }
  }
}

class ExampleLoop {
  private var subject = PassthroughSubject<Int, Never>()
  
  var publisher: some Publisher<Int, Never> {
    subject.eraseToAnyPublisher()
  }
  
  init() {
    repeatedValues { [subject] number in
      subject.send(number)
    }
  }
}

func repeatedValuesInCombine() {
  ExampleLoop()
    .publisher
    .sink { value in
      print("loop: \(value)")
    }
    .store(in: &cancelBag)
}

// MARK: - Throttle

func backPressureExampleUsingThrottle() {
  let subject = PassthroughSubject<Int, Never>()
  
  for i in 1...5 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
      print("new send: \(i)")
      subject.send(i)
    }
  }
  
  subject.throttle(for: 3, scheduler: DispatchQueue.main, latest: true)
    .sink { value in
      print("new received: \(value)")
    }
    .store(in: &cancelBag)
}

// MARK: - Debounce

func backPressureExampleUsingDebounce() {
  let subject = PassthroughSubject<Int, Never>()
  
  for i in 1...5 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
      print("new send: \(i)")
      subject.send(i)
    }
  }
  
  subject
    .debounce(for: 3, scheduler: DispatchQueue.main)
    .sink { value in
      print("new received: \(value)")
    }
    .store(in: &cancelBag)
}

// MARK: - Collect

func exampleCollect() {
  let subject = PassthroughSubject<Int, Never>()
  
  for i in 1...5 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
      print("new send: \(i)")
      subject.send(i)
    }
  }
  
  subject
//    .collect(3)
    .collect(.byTime(DispatchQueue.main, 3))
    .sink { value in
      print("new received: \(value)")
    }
    .store(in: &cancelBag)
}

// MARK: - Custom subscriber

class CustomSubscriber: Subscriber {
  typealias Input = Int
  typealias Failure = Never
  
  var subscription: Subscription?
  
  func receive(subscription: Subscription) {
    print("custom subscriber")
    subscription.request(.max(1))
  }
  
  func receive(_ input: Int) -> Subscribers.Demand {
    print("custom subscriber received: \(input)")
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.subscription?.request(.max(2))
    }
    return .none
  }
  
  func receive(completion: Subscribers.Completion<Never>) {
    
  }
}

func customSubscriber() {
  let subject = PassthroughSubject<Int, Never>()
  
  for i in 1...5 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
      print("new send: \(i)")
      subject.send(i)
    }
  }
  
  subject
    .subscribe(CustomSubscriber())
}


// MARK: - Test Publishers
/*
 
extension XCTestCase {
  
  func awaitPublisher<P: Publisher>(_ publisher: P, timeOut: TimeInterval = 10,
                           testName: StaticString = #function) throws -> [P.Output] {
    var values = [P.Output]()
    var reportedError: Error?
    
    let expectation = self.expectation(description: "Awaiting publisher in test \(testName)")
    
    let cancelBag = publisher
      .sink { result in
        switch result {
        case .failure(let error):
          reportedError = error
        case .finished:
          expectation.fulfill()
        }
      } receiveValue: { value in
        values.append(value)
      }
    waitForExpectations(timeout: timeOut)
    cancelBag.cancel()
    
    if let reportedError {
      throw reportedError
    }
    return values
  }
}


func testPublisher() throws {
  let sut = [1, 3, 5, 7, 9].publisher
    
  let values = try? XCTestCase.awaitPublisher(sut)
  
  XCTAssert(values.allSatisfy { $0.isMultiple(of: 2) == false })
}

*/


