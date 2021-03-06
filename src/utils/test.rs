use utils::environment::EnvironmentUtils;

use std::fs;

pub struct TestUtils {}

impl TestUtils {
    pub fn cleanup_sovrin_home() {
        let path = EnvironmentUtils::sovrin_home_path();
        if path.exists() {
            fs::remove_dir_all(path).unwrap();
        }
    }

    pub fn cleanup_temp() {
        let path = EnvironmentUtils::tmp_path();
        if path.exists() {
            fs::remove_dir_all(path).unwrap();
        }
    }

    pub fn cleanup_storage() {
        TestUtils::cleanup_sovrin_home();
        TestUtils::cleanup_temp();
    }
}

macro_rules! assert_match {
    ($pattern:pat, $var:expr) => (
        assert!(match $var {
            $pattern => true,
            _ => false
        })
    );
}