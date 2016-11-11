//
//  ViewController.swift
//  LocalChat
//
//  Created by JAMES IKELER on 11/9/16.
//  Copyright © 2016 JAMES IKELER. All rights reserved.
//


import UIKit
import MultipeerConnectivity
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var Browser:MCBrowserViewController!
    var Session:MCSession!
    var ID:MCPeerID!
    var Assistant:MCAdvertiserAssistant!
    
    var messages:[JSQMessage] = []
    var CanSend:Bool = false
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.inputToolbar.contentView.rightBarButtonItem.isEnabled = false
        ID = MCPeerID(displayName: UIDevice.current.name)
        self.senderDisplayName = ID.displayName
        self.senderId = "\(UIDevice.current.identifierForVendor)"
         Session = MCSession(peer: ID,  securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        self.Session.delegate = self
        Browser = MCBrowserViewController(serviceType: "LocalChat", session: Session)
        self.Browser.delegate = self
        self.Assistant = MCAdvertiserAssistant(serviceType: "LocalChat", discoveryInfo: nil, session: Session)
        }

    
    func GetPeers() -> Bool {
        if Session.connectedPeers.count == 0 {
            return false
        } else {
            return true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        //Called when browser view is dismissed
        self.dismiss(animated: true, completion: nil)
        Assistant.stop()
        CanSend = true
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        //Called when browser view is cancelled
        self.dismiss(animated: true, completion: nil)
        Assistant.stop()
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async(execute: {
            var messageDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as! Dictionary<String, AnyObject>
            if let Message = messageDictionary["message"] {
                if let SenderID = messageDictionary["senderId"] {
                    if let DisplayName = messageDictionary["DisplayName"] {
                    self.messages.append(JSQMessage(senderId: SenderID as? String, senderDisplayName: DisplayName as? String, date: NSDate() as Date!, text: Message as? String))
                        self.collectionView.reloadData()
                    }
                }
            }
        })
    }
    
}


func GetDate() -> NSAttributedString {
    let currentDateTime = Date()
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return NSAttributedString(string: formatter.string(from: currentDateTime))
}



//Unused functions that came With the Delegate

extension ChatViewController {
    
    @objc(session:didStartReceivingResourceWithName:fromPeer:withProgress:) func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress)  {
        
    }
    
    @objc(session:didFinishReceivingResourceWithName:fromPeer:atURL:withError:) func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL, withError error: Error?)  {
    }
    
    @objc(session:didReceiveStream:withName:fromPeer:) func session(_ session: MCSession, didReceive stream: InputStream,
                 withName streamName: String, fromPeer peerID: MCPeerID)  {
    }
    
    @objc(session:peer:didChangeState:) func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState)  {
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        if data.senderId == self.senderId {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let data = messages[indexPath.row]
        if data.senderId == self.senderId {
            return nil
        } else {
            return NSAttributedString(string: data.senderDisplayName)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        if data.senderId == self.senderId {
            return 0.0
        } else {
            return 13.0
        }
    }
    
   

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if GetPeers() {
            self.inputToolbar.contentView.textView.text = ""
            CanSend = false
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = false
            self.messages.append(JSQMessage(senderId: senderId as? String, displayName: senderDisplayName as? String, text: text as? String))
            self.collectionView.reloadData()
        
            let MessageData: [String:String] = [
            "senderId" : senderId,
            "DisplayName" : senderDisplayName,
            "message" : text
            ]
            let NSMessageData = NSDictionary(dictionary: MessageData)
            var data = NSKeyedArchiver.archivedData(withRootObject: NSMessageData)
            var error:NSError
            do {
                try self.Session.send(data, toPeers: Session.connectedPeers, with: .reliable)
            } catch {
                print(error)
            }
        } else {
            //Show alert if none is in the room
            let alert = UIAlertController(title: "Nobody is here!", message: "There is no one in the chat! ", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok :(", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.inputToolbar.contentView.textView.text = ""
        }
        
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        CanSend = true
        if CanSend == true && self.inputToolbar.contentView.textView.text != ""  {
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
        } else if self.inputToolbar.contentView.textView.text == "" {
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = false
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.present(Browser, animated: true, completion: nil)
        self.Assistant.start()
    }
    
}
