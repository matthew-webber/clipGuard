import Foundation

protocol Transform: AnyObject {
    var id: String { get }
    var kind: String { get }
    var isEnabled: Bool { get }
    func apply(_ input: String, context: TransformContext) -> TransformResult?
}
