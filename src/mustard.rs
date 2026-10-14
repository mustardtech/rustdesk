use hbb_common::config;

pub fn load() -> bool {
    let (name, connection_type) = match option_env!("MUSTARD_EDITION") {
        Some("support") => ("Mustard Support", "incoming"),
        Some("remote") => ("Mustard Remote", ""),
        _ => return false,
    };

    *config::APP_NAME.write().unwrap() = name.to_owned();
    config::HARD_SETTINGS
        .write()
        .unwrap()
        .insert("conn-type".to_owned(), connection_type.to_owned());

    let mut settings = config::OVERWRITE_SETTINGS.write().unwrap();
    for (key, value) in [
        ("custom-rendezvous-server", option_env!("RENDEZVOUS_SERVER")),
        ("relay-server", option_env!("MUSTARD_RELAY_SERVER")),
        ("key", option_env!("RS_PUB_KEY")),
        ("api-server", option_env!("API_SERVER")),
    ] {
        if let Some(value) = value.filter(|value| !value.is_empty()) {
            settings.insert(key.to_owned(), value.to_owned());
        }
    }
    true
}
