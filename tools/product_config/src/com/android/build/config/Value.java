/*
 * Copyright (C) 2020 The Android Open Source Project
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
import java.util.List;
import java.util.regex.Pattern;

/**
 * Class to hold the two types of variables we support, strings and lists of strings.
 */
public class Value {
    private static final Pattern SPACES = Pattern.compile("\\s+");

    private final VarType mVarType;
    private final Str mStr;
    private final ArrayList<Str> mList;

    /**
     * Construct an appropriately typed empty value.
     */
    public Value(VarType varType) {
        mVarType = varType;
        if (varType == VarType.LIST) {
            mStr = null;
            mList = new ArrayList();
            mList.add(new Str(""));
        } else {
            mStr = new Str("");
            mList = null;
        }
    }

    public Value(VarType varType, Str str) {
        mVarType = varType;
        mStr = str;
        mList = null;
    }

    public Value(List<Str> list) {
        mVarType = VarType.LIST;
        mStr = null;
        mList = new ArrayList(list);
    }

    public VarType getVarType() {
        return mVarType;
    }

    public Str getStr() {
        return mStr;
    }

    public List<Str> getList() {
        return mList;
    }

    /**
     * Normalize a string that is behaving as a list.
     */
    public static String normalize(String str) {
        if (str == null) {
            return null;
        }
        return SPACES.matcher(str.toString().trim()).replaceAll(" ");
    }

    /**
     * Normalize a string that is behaving as a list.
     */
    public static Str normalize(Str str) {
        if (str == null) {
            return null;
        }
        return new Str(str.getPosition(), normalize(str.toString()));
    }

    /**
     * Normalize a this Value into the same format as normalize(Str).
     */
    public Str normalize() {
        if (mStr != null) {
            return normalize(mStr);
        }

        if (mList.size() == 0) {
            return new Str("");
        }

        StringBuilder result = new StringBuilder();
        final int size = mList.size();
        boolean first = true;
        for (int i = 0; i < size; i++) {
            String s = mList.get(i).toString().trim();
            if (s.length() > 0) {
                if (!first) {
                    result.append(" ");
                } else {
                    first = false;
                }
                result.append(s);
            }
        }

        // Just use the first item's position.
        return new Str(mList.get(0).getPosition(), result.toString());
    }

    /**
     * Normalize a this Value into the same format as normalize(Str).
     */
    public static Str normalize(Value val) {
        if (val == null) {
            return null;
        }
        return val.normalize();
    }

    /**
     * Put each word in 'str' on its own line in make format. If 'str' is null,
     * "<null>" is returned.
     */
    public static String oneLinePerWord(String str) {
        if (str == null) {
            return "<null>";
        }
        return SPACES.matcher(str.toString().trim()).replaceAll(" \\\n  ");
    }

    /**
     * Put each word in 'str' on its own line in make format. If 'str' is null,
     * "<null>" is returned.
     */
    public static Str oneLinePerWord(Str str) {
        if (str == null) {
            return new Str("<null>");
        }
        return new Str(str.getPosition(), oneLinePerWord(str.toString()));
    }

    /**
     * Put each word in 'str' on its own line in make format. If 'str' is null,
     * "<null>" is returned.
     */
    public static Str oneLinePerWord(Value val) {
        if (val == null) {
            return new Str("<null>");
        }
        return oneLinePerWord(val.normalize());
    }

    /**
     * Return a string representing this value with detailed debugging information.
     */
    public String debugString() {
        final StringBuilder str = new StringBuilder("Value(type=");
        str.append(mVarType.toString());
        str.append(" mStr=");
        if (mStr == null) {
            str.append("null");
        } else {
            str.append("\"");
            str.append(mStr.toString());
            str.append("\" (");
            str.append(" (");
            str.append(mStr.getPosition().toString());
            str.append(")");
        }
        str.append(" mList=");
        if (mList == null) {
            str.append("null");
        } else {
            str.append("[");
            for (Str s: mList) {
                str.append("\"");
                str.append(s.toString());
                str.append("\" (");
                str.append(s.getPosition().toString());
                str.append(")");
            }
            str.append(" ]");
        }
        str.append(")");
        return str.toString();
    }
}

