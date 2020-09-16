//
//  Swipe.swift
//  Eureka
//
//  Created by Marco Betschart on 14.06.17.
//  Copyright © 2017 Xmartlabs. All rights reserved.
//

import Foundation
import UIKit

public typealias SwipeActionHandler = (SwipeAction, BaseRow, ((Bool) -> Void)?) -> Void

public class SwipeAction: ContextualAction {
    let handler: SwipeActionHandler
    let style: Style

    public var actionBackgroundColor: UIColor?
    public var image: UIImage?
    public var title: String?

    @available (*, deprecated, message: "Use actionBackgroundColor instead")
    public var backgroundColor: UIColor? {
        get { return actionBackgroundColor }
        set { self.actionBackgroundColor = newValue }
    }

    public init(style: Style, title: String?, handler: @escaping SwipeActionHandler){
        self.style = style
        self.title = title
        self.handler = handler
    }

    func contextualAction(forRow: BaseRow) -> ContextualAction {
        var action: ContextualAction
        if #available(iOS 11, *){
            action = UIContextualAction(style: style.contextualStyle as! UIContextualAction.Style, title: title){ [weak self] action, view, completion -> Void in
                guard let strongSelf = self else{ return }
                strongSelf.handler(strongSelf, forRow) { shouldComplete in
                    if #available(iOS 13, *) { // starting in iOS 13, completion handler is not removing the row automatically, so we need to remove it ourselves
                        if shouldComplete && action.style == .destructive {
                            forRow.section?.remove(at: forRow.indexPath!.row)
                        }
                    }
                    completion(shouldComplete)
                }
            }
        } else {
            action = UITableViewRowAction(style: style.contextualStyle as! UITableViewRowAction.Style,title: title){ [weak self] (action, indexPath) -> Void in
                guard let strongSelf = self else{ return }
				strongSelf.handler(strongSelf, forRow) { _ in
					DispatchQueue.main.async {
						guard action.style == .destructive else {
                            #if iMessage
                            if #available(iOS 10.0, *) {
                                if let formviewcontroller = forRow.baseCell?.formViewController() as? FormMessagesViewController {
                                    formviewcontroller.tableView?.setEditing(false, animated: true)
                                }
                            }
                            #else
                            if let formviewcontroller = forRow.baseCell?.formViewController() as? FormViewController {
                                formviewcontroller.tableView?.setEditing(false, animated: true)
                            }
                            #endif
							return
						}
						forRow.section?.remove(at: indexPath.row)
					}
				}
            }
        }
        if let color = self.actionBackgroundColor {
            action.actionBackgroundColor = color
        }
        if let image = self.image {
            action.image = image
        }
        return action
    }
	
    public enum Style {
        case normal
        case destructive
        
        var contextualStyle: ContextualStyle {
            if #available(iOS 11, *){
                switch self{
                case .normal:
                    return UIContextualAction.Style.normal
                case .destructive:
                    return UIContextualAction.Style.destructive
                }
            } else {
                switch self{
                case .normal:
                    return UITableViewRowAction.Style.normal
                case .destructive:
                    return UITableViewRowAction.Style.destructive
                }
            }
        }
    }
}

public struct SwipeConfiguration {
	
    unowned var row: BaseRow
    
	init(_ row: BaseRow){
		self.row = row
	}
	
	public var performsFirstActionWithFullSwipe = false
	public var actions: [SwipeAction] = []
}

extension SwipeConfiguration {
    @available(iOS 11.0, *)
    var contextualConfiguration: UISwipeActionsConfiguration? {
        let contextualConfiguration = UISwipeActionsConfiguration(actions: self.contextualActions as! [UIContextualAction])
        contextualConfiguration.performsFirstActionWithFullSwipe = self.performsFirstActionWithFullSwipe
        return contextualConfiguration
    }

    var contextualActions: [ContextualAction]{
        return self.actions.map { $0.contextualAction(forRow: self.row) }
    }
}

protocol ContextualAction {
    var actionBackgroundColor: UIColor? { get set }
    var image: UIImage? { get set }
    var title: String? { get set }
}

extension UITableViewRowAction: ContextualAction {
    public var image: UIImage? {
        get { return nil }
        set { return }
    }

    public var actionBackgroundColor: UIColor? {
        get { return backgroundColor }
        set { self.backgroundColor = newValue }
    }
}

@available(iOS 11.0, *)
extension UIContextualAction: ContextualAction {

    public var actionBackgroundColor: UIColor? {
        get { return backgroundColor }
        set { self.backgroundColor = newValue }
    }

}

public protocol ContextualStyle{}
extension UITableViewRowAction.Style: ContextualStyle {}

@available(iOS 11.0, *)
extension UIContextualAction.Style: ContextualStyle {}
