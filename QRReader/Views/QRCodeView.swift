//
//  QRCodeView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import AVFoundation
import SwiftUI

struct QRCodeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> QRCodeViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: QRCodeViewController, context: Context) {}
}

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let session: AVCaptureSession = .init()
    let preview: AVCaptureVideoPreviewLayer = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(resumeScanning), name: .AVCaptureResumeScan, object: nil)
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        let metadata: AVCaptureMetadataOutput = .init()

        if session.canAddOutput(metadata) {
            session.addOutput(metadata)
            metadata.setMetadataObjectsDelegate(self, queue: .main)
            metadata.metadataObjectTypes = [.qr]
        }
        preview.session = session
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.safeAreaLayoutGuide.layoutFrame
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        if let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadata.stringValue
        {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            NotificationCenter.default.post(name: .AVCaptureMetadataOoutputDetected, object: stringValue)
            print(stringValue)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .default).async { [self] in
                session.startRunning()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .default).async { [self] in
                session.stopRunning()
            }
        }
    }

    @objc private func resumeScanning() {
        if !session.isRunning {
            DispatchQueue.global(qos: .default).async { [self] in
                session.startRunning()
            }
        }
    }
}

#Preview {
    QRCodeView()
}
