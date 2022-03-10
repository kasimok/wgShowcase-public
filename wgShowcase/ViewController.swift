import UIKit
import WireGuardKit

let wgName = "WireGuard Default Conf"

class ViewController: UIViewController {
    
    var wgConfigString: String?
    
    var tunnelsManager: TunnelsManager?
    var onTunnelsManagerReady: ((TunnelsManager) -> Void)?

    /// Deafult config save location
    lazy var configLocation: URL = {
        let documentRoot = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        precondition(documentRoot.count == 1, "Document Root Not Exist!")
        return URL(string: (documentRoot.first! as NSString).appendingPathComponent("WireGuard.conf"))!
    }()
    
    @IBOutlet weak var wgConfigField: UITextView!
    
    @IBOutlet weak var wgApiRequestingIndicator: UIActivityIndicatorView!
    
    
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet weak var connectIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusSwitch: UISwitch!
    
    fileprivate func loadConfig() {
        guard let tunnelsManager = tunnelsManager else {
            return
        }
        
        
        //Tunnel Already Imported. Quit
        guard tunnelsManager.tunnel(named: wgName) == nil else{
            DispatchQueue.main.async {
                self.wgApiRequestingIndicator.stopAnimating()
                self.wgApiRequestingIndicator.isHidden = true
                
                //Enable switch
                self.statusSwitch.isEnabled = true
            }
            return
        }
        
        wgApiRequestingIndicator.startAnimating()
        
        let wgConfigString:String? = nil
        
        
        precondition(wgConfigString != nil, "Bro, fill this wg config string!")
        
        
        
        var tunnelConfiguration: TunnelConfiguration?
        do {
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: wgConfigString!, called: wgName)
        } catch let error {
            //TODO: Prompt Parse Error
            debugPrint("Tunnel Configuration Parse Error: \(error.localizedDescription)")
            return
        }
        
        if let tunnelConfiguration = tunnelConfiguration {
            
            tunnelsManager.add(tunnelConfiguration: tunnelConfiguration) { results in
                switch results{
                case .success:
                    //TODO: Show Success
                    wg_log(.info, message: "Successfully Imported Config")
                case let .failure(tmError):
                    //TODO: Manager import failed
                    wg_log(.error, message: "Tunnel Import Failed:\(tmError.localizedDescription)")
                }
            }
        }
        self.statusSwitch.isEnabled = true
        
    }
    
    fileprivate func configureUI(){
        connectIndicator.isHidden = true
        connectIndicator.stopAnimating()
        statusSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }
    
    fileprivate func loadTunnel(){
        // Create the tunnels manager, and when it's ready, inform tunnelsListVC
        TunnelsManager.create { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                fatalError("Tunnel manager craete Failed, error: \(error.localizedDescription)")
            case .success(let tunnelsManager):
                self.tunnelsManager = tunnelsManager
                tunnelsManager.activationDelegate = self
                self.onTunnelsManagerReady?(tunnelsManager)
                self.onTunnelsManagerReady = nil
                self.loadConfig()
            }
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadTunnel()
    }
    
    
    
    
    @objc private func switchToggled() {
        debugPrint("switchToggled")
        let isOn = statusSwitch.isOn
        guard let tunnelsManager = self.tunnelsManager else { return }
        guard let tunnel = tunnelsManager.tunnel(named: wgName) else {return}
        connectIndicator.isHidden = false
        connectIndicator.startAnimating()
        if tunnel.hasOnDemandRules {
            tunnelsManager.setOnDemandEnabled(isOn, on: tunnel) { error in
                if error == nil && !isOn {
                    tunnelsManager.startDeactivation(of: tunnel)
                }
            }
        } else {
            if isOn {
                tunnelsManager.startActivation(of: tunnel)
            } else {
                tunnelsManager.startDeactivation(of: tunnel)
            }
        }
    }
}



//MARK: - Tun

extension ViewController:TunnelsManagerActivationDelegate{
    func tunnelActivationAttemptFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationAttemptError) {
        debugPrint("\(#function) called")
        connectIndicator.isHidden = true
        connectIndicator.stopAnimating()
    }
    
    func tunnelActivationAttemptSucceeded(tunnel: TunnelContainer) {
        debugPrint("\(#function) called")
        connectIndicator.isHidden = true
        connectIndicator.stopAnimating()
    }
    
    func tunnelActivationFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationError) {
        debugPrint("\(#function) called")
        connectIndicator.isHidden = true
        connectIndicator.stopAnimating()
    }
    
    func tunnelActivationSucceeded(tunnel: TunnelContainer) {
        debugPrint("\(#function) called")
        connectIndicator.isHidden = true
        connectIndicator.stopAnimating()
    }
    
    
}
