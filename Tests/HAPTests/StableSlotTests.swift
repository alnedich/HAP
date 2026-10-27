@testable import HAP
import XCTest

/// Controllers key automations by instance ID; a service added or removed must
/// leave the others' IDs alone (HAP 2.6.1.2).
class StableSlotTests: XCTestCase {
    private func sensors(_ slots: [Int]) -> [Service] {
        slots.map { slot in
            let service = Service.TemperatureSensor()
            service.stableSlot = slot
            return service
        }
    }

    func testSlottedServicesKeepTheirIDsWhenAnotherIsRemoved() {
        let all = Accessory(info: .init(name: "Yard", serialNumber: "A"), type: .sensor, services: sensors([0, 1, 2]))
        let without1 = Accessory(info: .init(name: "Yard", serialNumber: "A"), type: .sensor, services: sensors([0, 2]))
        XCTAssertEqual(all.services[0].iid, 1)
        XCTAssertEqual(all.services[3].iid, without1.services[2].iid)
        XCTAssertEqual(all.services[3].characteristics.map(\.iid), without1.services[2].characteristics.map(\.iid))
        let ids = all.services.flatMap { [$0.iid] + $0.characteristics.map(\.iid) }
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testUnslottedAccessoryNumbersInOrder() {
        let plain = Accessory(info: .init(name: "Lamp", serialNumber: "B"), type: .sensor,
                              services: [Service.TemperatureSensor()])
        XCTAssertEqual(plain.services[1].iid, plain.services[0].characteristics.count + 2)
    }
}
