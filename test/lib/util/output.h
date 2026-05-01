#pragma once

#include <common/types/big_int.h>
#include <magic_enum/magic_enum.hpp>

#include <boost/test/unit_test.hpp>

#include <ostream>

namespace boost {
namespace test_tools {
namespace tt_detail {

template <typename Enum>
requires std::is_enum_v<Enum>
struct print_log_value<Enum> {
    void operator()(std::ostream& os, const Enum& value) const {
        if (auto name = magic_enum::enum_name(value); !name.empty()) {
            os << name;
        } else {
            os << "Unknown";
        }
    }
};

template <typename T>
requires requires(std::ostream& os, const T& v) {
    { os << v } -> std::same_as<std::ostream&>;
}

struct print_log_value<std::vector<T>> {
    void operator()(std::ostream& os, std::vector<T> const& value) {
        os << '{';
        for (auto x : value)
            os << x << ' ';
        os << '}';
    }
};

template <> struct print_log_value<__uint128_t> {
    void operator()(std::ostream& os, const __uint128_t& value) const {
        ::operator<<(os, value);
    }
};

} // namespace tt_detail
} // namespace test_tools
} // namespace boost
