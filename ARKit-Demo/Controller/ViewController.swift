//
//  ViewController.swift
//  ARKit-Demo
//
//  Created by Ammad on 10/11/2020.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var planeDetectedLabel: UILabel!
    
    // MARK: - Variables
    
    let session = ARSession()
    private var selectedNode: SCNNode?
    private var originalRotation: SCNVector3?
    
    let sessionConfiguration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal // direction in which to detect plane
        return config
    }()
    
    // MARK: - UIViewController LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConfigurations()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            session.run(sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
            
        } else {
            // can be handled via Alert/otherwise based on business requirements
            print("Sorry, your device doesn't support ARKit")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Private Methods
    
    fileprivate func setupConfigurations() {
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // This is an optioanl personal preference for ease of debugging
        sceneView.showsStatistics = true
        
        // Use the session that we created
        sceneView.session = session
        
        // Use the default lighting so that our objects are illuminated
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // show Feature Points
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Update at 60 frames per second (recommended by Apple)
        sceneView.preferredFramesPerSecond = 60
    }
    
    fileprivate func setupGestures() {
        // Tracks Tap on screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        // Tracks pinch on screen
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        // Tracks pan on the screen
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        // Tracks rotation gestures on the screen
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(rotationGesture)

    }
    
    fileprivate func addItemToPosition(_ position: SCNVector3) {
        let scene = SCNScene(named: "art.scnassets/gramophone.scn")
        
        DispatchQueue.main.async {
            
            // recursively is set to false since Gramophone is an immediate children of root node in hirearchy
            if let node = scene?.rootNode.childNode(withName: "Gramophone", recursively: false) {
                // Scale down the model to fit the real world better
                node.scale = SCNVector3(0.002, 0.002, 0.002)
                // assign node a position
                node.position = position
                // add node to scene view
                self.sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    fileprivate func node(at position: CGPoint) -> SCNNode? {
        return sceneView.hitTest(position, options: nil)
            .first?.node
    }
    
    // MARK: - Selectors
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        
        guard let sceneViewTappedOn = gesture.view as? ARSCNView else { return }
        
        let touchCoordinates = gesture.location(in: sceneViewTappedOn)
        
        guard let query = sceneView.raycastQuery(from: touchCoordinates, allowing: .existingPlaneInfinite, alignment: .any) else { return }
        
        let results = sceneView.session.raycast(query)
        
        // Making sure we have atleast one hitTestResult
        guard let hitTestResult = results.first else { return }
        
        // Position of horizontal surface is present in 3rd column
        let position = SCNVector3(hitTestResult.worldTransform.columns.3.x,
                                  hitTestResult.worldTransform.columns.3.y,
                                  hitTestResult.worldTransform.columns.3.z)
        
        addItemToPosition(position)
    }
    
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        
        guard let sceneViewTappedOn = gesture.view as? ARSCNView else { return }
        
        let touchCoordinates = gesture.location(in: sceneViewTappedOn)
     
        let hitTest = sceneView.hitTest(touchCoordinates)
        
        // Making sure we have atleast one hitTestResult
        guard let hitTestResult = hitTest.first else { return }
        
        let node = hitTestResult.node
        let pinchAction = SCNAction.scale(by: gesture.scale, duration: 0)
        node.runAction(pinchAction)
        gesture.scale = 1.0  // for uniform scaling
    }
    
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        // Find the location in the view
        guard let sceneViewTappedOn = gesture.view as? ARSCNView else { return }
        
        let touchCoordinates = gesture.location(in: sceneViewTappedOn)
            
        switch gesture.state {
        
        case .began:
            // Choose the node to move
            selectedNode = node(at: touchCoordinates)
        
        case .changed:
            // Move the node based on the real world translation

            guard let sceneViewTappedOn = gesture.view as? ARSCNView else { return }
            
            let touchCoordinates = gesture.location(in: sceneViewTappedOn)
            
            guard let query = sceneView.raycastQuery(from: touchCoordinates, allowing: .existingPlaneInfinite, alignment: .any) else { return }
            
            let results = sceneView.session.raycast(query)
            
            // Making sure we have atleast one hitTestResult
            guard let hitTestResult = results.first else { return }
            
            let transform = hitTestResult.worldTransform
            let newPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
       
        default:
            // Remove the reference to the node
            selectedNode = nil
        }
    }
    
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        // Find the location in the view
        guard let sceneViewTappedOn = gesture.view as? ARSCNView else { return }
        
        let touchCoordinates = gesture.location(in: sceneViewTappedOn)
            
        guard let node = node(at: touchCoordinates) else { return }
            
        switch gesture.state {
        
        case .began:
            originalRotation = node.eulerAngles
        
        case .changed:
            
            guard var originalRotation = originalRotation else { return }
            
            originalRotation.y -= Float(gesture.rotation)
            node.eulerAngles = originalRotation
        
        default:
            originalRotation = nil
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor is ARPlaneAnchor  else { return }
        
        // Main thread
        DispatchQueue.main.async {
            
            self.planeDetectedLabel.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                
                guard let self = self else { return }
                
                self.planeDetectedLabel.isHidden = true
            }
        }
    }
}
