/*
 * Copyright (C) 2021 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.build.config;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Compares the make-based configuration as reported by dumpconfig.mk
 * with what was computed from the new tool.
 */
public class OutputChecker {
    private final FlatConfig mConfig;

    private final TreeMap<String, Variable> mVariables;

    /**
     * Represents the before and after state of a variable.
     */
    public static class Variable {
        public final String name;
        public final VarType type;
        public final Str original;
        public final Value updated;
        public final Str normalizedOriginal;
        public final Str normalizedUpdated;

        public Variable(String name, VarType type, Str original) {
            this(name, type, null, null);
        }

        public Variable(String name, VarType type, Str original, Value updated) {
            this.name = name;
            this.type = type;
            this.original = original;
            this.updated = updated;
            this.normalizedOriginal = Value.normalize(original);
            this.normalizedUpdated = Value.normalize(updated);
        }

        /**
         * Return copy of this Variable with the updated field also set.
         */
        public Variable addUpdated(Value updated) {
            return new Variable(name, type, original, updated);
        }

        /**
         * Return whether normalizedOriginal and normalizedUpdate are equal.
         */
        public boolean isSame() {
            if (normalizedOriginal == normalizedUpdated) {
                return true;
            } else if (normalizedOriginal != null) {
                return normalizedOriginal.equals(normalizedUpdated);
            } else {
                return false;
            }
        }
    }

    /**
     * Construct OutputChecker with the config it will check.
     */
    public OutputChecker(FlatConfig config) {
        mConfig = config;
        mVariables = getVariables(config);
    }

    /**
     * Add a WARNING_DIFFERENT_FROM_KATI for each of the variables which have changed.
     */
    public void reportErrors(Errors errors) {
        for (Variable var: getDifferences()) {
            errors.WARNING_DIFFERENT_FROM_KATI.add("product_config processing differs from"
                    + " kati processing for " + var.type + " variable " + var.name + ": ");
            if (var.normalizedOriginal != null) {
                errors.WARNING_DIFFERENT_FROM_KATI.add(var.normalizedOriginal.getPosition(),
                        "original: \"" + var.normalizedOriginal + "\"");
            } else {
                errors.WARNING_DIFFERENT_FROM_KATI.add("original: null");
            }
            if (var.normalizedUpdated != null) {
                errors.WARNING_DIFFERENT_FROM_KATI.add(var.normalizedUpdated.getPosition(),
                        "updated: \"" + var.normalizedUpdated + "\"");
            } else {
                errors.WARNING_DIFFERENT_FROM_KATI.add("updated: null");
            }
        }
    }

    /**
     * Get the Variables that are different between the normalized form of the original
     * and updated.  If one is null and the other is not, even if one is an empty string,
     * the values are considered different.
     */
    public List<Variable> getDifferences() {
        final ArrayList<Variable> result = new ArrayList();
        for (Variable var: mVariables.values()) {
            if (!var.isSame()) {
                result.add(var);
            }
        }
        return result;
    }

    /**
     * Get all of the variables for this config.
     *
     * VisibleForTesting
     */
    static TreeMap<String, Variable> getVariables(FlatConfig config) {
        final TreeMap<String, Variable> result = new TreeMap();

        // Add the original values to mAll
        for (Map.Entry<String, Str> entry: getModifiedVars(config.getInitialVariables(),
                    config.getFinalVariables()).entrySet()) {
            final String name = entry.getKey();
            result.put(name, new Variable(name, config.getVarType(name), entry.getValue()));
        }

        // Add the updated values to mAll
        for (Map.Entry<String, Value> entry: config.getValues().entrySet()) {
            final String name = entry.getKey();
            final Value value = entry.getValue();
            Variable var = result.get(name);
            if (var == null) {
                result.put(name, new Variable(name, config.getVarType(name), null, value));
            } else {
                result.put(name, var.addUpdated(value));
            }
        }

        return result;
    }

    /**
     * Get the entries that are different in the two maps.
     */
    public static Map<String, Str> getModifiedVars(Map<String, Str> before,
            Map<String, Str> after) {
        final HashMap<String, Str> result = new HashMap();

        // Entries that were added or changed.
        for (Map.Entry<String, Str> afterEntry: after.entrySet()) {
            final String varName = afterEntry.getKey();
            final Str afterValue = afterEntry.getValue();
            final Str beforeValue = before.get(varName);
            if (beforeValue == null || !beforeValue.equals(afterValue)) {
                result.put(varName, afterValue);
            }
        }

        // removed Entries that were removed, we just treat them as  
        for (Map.Entry<String, Str> beforeEntry: before.entrySet()) {
            final String varName = beforeEntry.getKey();
            if (!after.containsKey(varName)) {
                result.put(varName, new Str(""));
            }
        }

        return result;
    }
}
