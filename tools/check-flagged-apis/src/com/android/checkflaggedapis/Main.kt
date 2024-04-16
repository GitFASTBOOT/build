/*
 * Copyright (C) 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
@file:JvmName("Main")

package com.android.checkflaggedapis

import android.aconfig.Aconfig
import com.android.tools.metalava.model.BaseItemVisitor
import com.android.tools.metalava.model.FieldItem
import com.android.tools.metalava.model.text.ApiFile
import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.ProgramResult
import com.github.ajalt.clikt.parameters.options.option
import com.github.ajalt.clikt.parameters.options.required
import com.github.ajalt.clikt.parameters.types.path
import java.io.InputStream
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Node

@JvmInline
value class Symbol(val name: String) {
  companion object {
    private val FORBIDDEN_CHARS = listOf('/', '#', '$')

    fun create(name: String): Symbol {
      var sanitized_name = name
      for (ch in FORBIDDEN_CHARS) {
        sanitized_name = sanitized_name.replace(ch, '.')
      }
      return Symbol(sanitized_name)
    }
  }

  init {
    require(!name.isEmpty()) { "empty string" }
    for (ch in FORBIDDEN_CHARS) {
      require(!name.contains(ch)) { "$name: contains $ch" }
    }
  }

  override fun toString(): String = name.toString()
}

@JvmInline
value class Flag(val name: String) {
  override fun toString(): String = name.toString()
}

class CheckCommand : CliktCommand() {
  private val api_signature_path by
      option("--api-signature")
          .path(mustExist = true, canBeDir = false, mustBeReadable = true)
          .required()
  private val flag_values_path by
      option("--flag-values")
          .path(mustExist = true, canBeDir = false, mustBeReadable = true)
          .required()
  private val api_versions_path by
      option("--api-versions")
          .path(mustExist = true, canBeDir = false, mustBeReadable = true)
          .required()

  override fun run() {
    @Suppress("UNUSED_VARIABLE")
    val flagged_symbols =
        api_signature_path.toFile().inputStream().use { inputStream ->
          parseApiSignature(api_signature_path.toString(), inputStream)
        }
    @Suppress("UNUSED_VARIABLE")
    val flags =
        flag_values_path.toFile().inputStream().use { inputStream -> parseFlagValues(inputStream) }
    @Suppress("UNUSED_VARIABLE")
    val exported_symbols =
        api_versions_path.toFile().inputStream().use { inputStream ->
          parseApiVersions(inputStream)
        }
    throw ProgramResult(0)
  }
}

private fun parseApiSignature(path: String, input: InputStream): Set<Pair<Symbol, Flag>> {
  // TODO(334870672): add support for classes and metods
  val output = mutableSetOf<Pair<Symbol, Flag>>()
  val visitor =
      object : BaseItemVisitor() {
        override fun visitField(field: FieldItem) {
          val flag =
              field.modifiers
                  .findAnnotation("android.annotation.FlaggedApi")
                  ?.findAttribute("value")
                  ?.value
                  ?.value() as? String
          if (flag != null) {
            val symbol = Symbol.create(field.baselineElementId())
            output.add(Pair(symbol, Flag(flag)))
          }
        }
      }
  val codebase = ApiFile.parseApi(path, input)
  codebase.accept(visitor)
  return output
}

private fun parseFlagValues(input: InputStream): Map<Flag, Boolean> {
  val parsedFlags = Aconfig.parsed_flags.parseFrom(input).getParsedFlagList()
  return parsedFlags.associateBy(
      { Flag("${it.getPackage()}.${it.getName()}") },
      { it.getState() == Aconfig.flag_state.ENABLED })
}

private fun parseApiVersions(input: InputStream): Set<Symbol> {
  fun Node.getAttribute(name: String): String? = getAttributes()?.getNamedItem(name)?.getNodeValue()

  val output = mutableSetOf<Symbol>()
  val factory = DocumentBuilderFactory.newInstance()
  val parser = factory.newDocumentBuilder()
  val document = parser.parse(input)
  val fields = document.getElementsByTagName("field")
  // ktfmt doesn't understand the `..<` range syntax; explicitly call .rangeUntil instead
  for (i in 0.rangeUntil(fields.getLength())) {
    val field = fields.item(i)
    val fieldName = field.getAttribute("name")
    val className =
        requireNotNull(field.getParentNode()) { "Bad XML: top level <field> element" }
            .getAttribute("name")
    output.add(Symbol.create("$className.$fieldName"))
  }
  return output
}

fun main(args: Array<String>) = CheckCommand().main(args)
