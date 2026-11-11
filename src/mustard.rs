use hbb_common::config;

pub fn voice_calls_disabled() -> bool {
    matches!(option_env!("MUSTARD_EDITION"), Some("support" | "remote"))
}

pub fn text_chat_disabled() -> bool {
    voice_calls_disabled()
}

pub fn display_name(name: String) -> String {
    match name.as_str() {
        "MustardSupport" => "Mustard Support".to_owned(),
        "MustardRemote" => "Mustard Remote".to_owned(),
        _ => name,
    }
}

pub fn load() -> bool {
    let (name, connection_type, theme) = match option_env!("MUSTARD_EDITION") {
        Some("support") => ("MustardSupport", "incoming", "light"),
        Some("remote") => ("MustardRemote", "", "dark"),
        _ => return false,
    };

    *config::APP_NAME.write().unwrap() = name.to_owned();
    config::HARD_SETTINGS
        .write()
        .unwrap()
        .insert("conn-type".to_owned(), connection_type.to_owned());
    config::BUILTIN_SETTINGS
        .write()
        .unwrap()
        .insert("hide-powered-by-me".to_owned(), "Y".to_owned());
    config::OVERWRITE_LOCAL_SETTINGS
        .write()
        .unwrap()
        .insert("theme".to_owned(), theme.to_owned());

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
