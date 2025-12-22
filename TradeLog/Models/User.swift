import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String?
    var fullname: String?
    var capital: Double?
}
