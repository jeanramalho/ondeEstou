//
//  ondeEstouViewController.swift
//  ondeEstou
//
//  Created by Jean Ramalho on 11/03/25.
//
import UIKit
import MapKit
import CoreLocation

// MARK: - ViewController principal
class ondeEstouViewController: UIViewController {
    
    // MARK: - Propriedades
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private var isFirstLocationUpdate = true
    
    // MARK: - Ciclo de Vida da View
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad chamado")
        setupUI()
        configureLocationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear chamado")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear chamado")
        
        // Verificar se já temos permissão de localização
        checkLocationAuthorizationAndStart()
    }
    
    // MARK: - Configuração da Interface
    private func setupUI() {
        title = "Onde Estou"
        view.backgroundColor = .white
        
        // Configuração do mapa
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Configurações do mapa
        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.delegate = self
        
        // Botão para centralizar na localização atual
        let locationButton = UIButton(type: .system)
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        locationButton.setImage(UIImage(systemName: "location.circle.fill"), for: .normal)
        locationButton.tintColor = .systemBlue
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 25
        locationButton.layer.shadowColor = UIColor.black.cgColor
        locationButton.layer.shadowOpacity = 0.2
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        locationButton.layer.shadowRadius = 4
        locationButton.addTarget(self, action: #selector(centerOnUserLocation), for: .touchUpInside)
        
        view.addSubview(locationButton)
        
        NSLayoutConstraint.activate([
            locationButton.heightAnchor.constraint(equalToConstant: 50),
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuração do LocationManager
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Não iniciar atualizações de localização aqui
        // Será feito após verificar autorização
    }
    
    // MARK: - Verificação de Autorização
    private func checkLocationAuthorizationAndStart() {
        print("Verificando autorização de localização...")
        
        // Primeiro verificar se os serviços de localização estão habilitados
        guard CLLocationManager.locationServicesEnabled() else {
            print("Serviços de localização desativados no dispositivo")
            showLocationServicesDisabledAlert()
            return
        }
        
        print("Serviços de localização estão habilitados")
        
        // Verificar o status de autorização
        let status = locationManager.authorizationStatus
        print("Status atual de autorização: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Permissão já concedida, iniciando serviços de localização")
            startLocationServices()
            
        case .notDetermined:
            print("Permissão ainda não determinada, solicitando...")
            // MUITO IMPORTANTE: Solicita autorização "durante o uso"
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            print("Permissão negada ou restrita")
            showLocationPermissionDeniedAlert()
            
        @unknown default:
            print("Status desconhecido")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: - Iniciar Serviços de Localização
    private func startLocationServices() {
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        
        // Se já tivermos uma localização, centralizar o mapa
        if let location = locationManager.location {
            centerMapOnLocation(location)
        } else {
            // Solicitar uma atualização única
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Centralizar Mapa
    private func centerMapOnLocation(_ location: CLLocation) {
        print("Centralizando mapa na localização: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        mapView.setRegion(region, animated: true)
    }
    
    @objc private func centerOnUserLocation() {
        print("Botão de centralizar localização pressionado")
        
        if let location = locationManager.location {
            centerMapOnLocation(location)
        } else {
            print("Localização atual não disponível, solicitando...")
            locationManager.requestLocation()
            
            // Mostrar um feedback ao usuário
            let alert = UIAlertController(
                title: "Buscando sua localização",
                message: "Aguarde enquanto obtemos sua localização atual...",
                preferredStyle: .alert
            )
            
            // Apresentar o alerta por 2 segundos
            present(alert, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Alertas
    private func showLocationServicesDisabledAlert() {
        let alert = UIAlertController(
            title: "Serviços de Localização Desativados",
            message: "Para mostrar sua localização no mapa, ative os Serviços de Localização nas Configurações do seu dispositivo.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Abrir Configurações", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showLocationPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permissão de Localização",
            message: "Para mostrar sua localização no mapa, permita o acesso à sua localização nas configurações do aplicativo.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Abrir Configurações", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        // Verificar se já existe um alerta sendo apresentado
        if self.presentedViewController == nil {
            present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ondeEstouViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Mudança no status de autorização: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Permissão concedida após mudança")
            startLocationServices()
            
        case .denied, .restricted:
            print("Permissão negada ou restrita após mudança")
            if self.presentedViewController == nil {
                showLocationPermissionDeniedAlert()
            }
            
        case .notDetermined:
            print("Status ainda não determinado")
            
        @unknown default:
            print("Status desconhecido após mudança")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Localização atualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Centralizar o mapa apenas na primeira atualização
        if isFirstLocationUpdate {
            isFirstLocationUpdate = false
            centerMapOnLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro ao obter localização: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Acesso à localização negado")
                if self.presentedViewController == nil {
                    showLocationPermissionDeniedAlert()
                }
                
            case .locationUnknown:
                print("Localização temporariamente indisponível")
                
            case .network:
                print("Erro de rede ao obter localização")
                
            default:
                print("Erro de localização: código \(clError.code.rawValue)")
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension ondeEstouViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Mapa atualizou localização do usuário: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
    }
}
