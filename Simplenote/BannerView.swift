import Foundation
import UIKit

// MARK: - BannerView
//
class BannerView: UIView {

    @IBOutlet
    private var backgroundView: UIView!

    @IBOutlet
    private var titleLabel: UILabel!

    @IBOutlet
    private var detailsLabel: UILabel!

    @IBOutlet
    private var topConstraint: NSLayoutConstraint!

    @IBOutlet
    private var widthConstraint: NSLayoutConstraint!

    @objc
    var appliesTopInset: Bool = false {
        didSet {
            topConstraint.constant = appliesTopInset ? Metrics.defaultTopInset : .zero
        }
    }

    var onPress: (() -> Void)?

    var preferredWidth: CGFloat? {
        didSet {
            guard let preferredWidth else {
                return
            }

            widthConstraint.constant = preferredWidth
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshInterface()
        setupTapRecognizer()
    }

    // MARK: - Actions

    @objc
    func bannerWasPressed() {
        onPress?()
    }

    private func setupTapRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(bannerWasPressed))
        backgroundView.addGestureRecognizer(tapRecognizer)
    }

    func refreshInterface(with style: BannerView.Style? = nil) {
        guard let style else {
            return
        }

        titleLabel.text = style.title
        detailsLabel.text = style.details
        titleLabel.textColor = style.textColor
        detailsLabel.textColor = style.textColor
        backgroundView.backgroundColor = style.backgroundColor
        backgroundView.layer.cornerRadius = Metrics.defaultCornerRadius
    }

    // MARK: - Style
    //
    struct Style {
        let title: String
        let details: String
        let textColor: UIColor
        let backgroundColor: UIColor

        // Leaving these styles in cause we may want them back someday
        static var sustainer: Style {
            Style(title: NSLocalizedString("You are a Simplenote Sustainer", comment: "Current Sustainer Title"),
                  details: NSLocalizedString("Thank you for your continued support", comment: "Current Sustainer Details"),
                  textColor: .white,
                  backgroundColor: .simplenoteSustainerViewBackgroundColor)
        }

        static var notSubscriber: Style {
            Style(title: NSLocalizedString("Become a Simplenote Sustainer", comment: "Become a Sustainer Title"),
                  details: NSLocalizedString("Support your favorite notes app to help unlock future features", comment: "Become a Sustainer Details"),
                  textColor: .white,
                  backgroundColor: .simplenoteBlue50Color)
        }

        static var collaborationRetirement: Style {
            Style(title: NSLocalizedString("Collaboration Retirement", comment: "Title annoucning collaboration retirement"), details: NSLocalizedString("Collaboration is being retired and will be disabled for all users July 1st.  For more details tap here", comment: "Description for retiring collaboration feature"), textColor: .white, backgroundColor: .simplenoteBlue50Color)
        }
    }

}

// MARK: - Metrics
//
private enum Metrics {
    static let defaultTopInset: CGFloat = 19
    static let defaultCornerRadius: CGFloat = 8
}
